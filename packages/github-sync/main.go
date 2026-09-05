// github-sync maintains disposable clones owned by a dedicated sync account.
// Refresh resets default branches, removes local edits/untracked/ignored files,
// and follows force pushes. Failed or disappeared repos are preserved.
// No hooks, submodules, LFS downloads or dependency installation.
// Tests: go test -race ./...; go vet ./...
package main

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"sync"
	"sync/atomic"
	"syscall"
	"time"
)

const owner = "shardulbee"

var repoName = regexp.MustCompile(`^[A-Za-z0-9_.-]+$`)

type repository struct {
	Name          string
	DefaultBranch string `json:"default_branch"`
	Private       bool
	Owner         struct{ Login string }
}

type synchronizer struct {
	root  string
	token string
	api   string
}

func (s synchronizer) git(dir string, args ...string) (string, error) {
	timeout := 25 * time.Second
	if args[0] == "clone" {
		timeout = 10 * time.Minute
	}
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()
	cmd := exec.CommandContext(ctx, "git", append([]string{
		"-c", "core.hooksPath=/dev/null", "-c", "credential.helper=",
	}, args...)...)
	cmd.Dir = dir
	cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	cmd.Cancel = func() error { return syscall.Kill(-cmd.Process.Pid, syscall.SIGKILL) }
	// Keep the token out of argv, logs, config files, and clone URLs.
	cmd.Env = append(os.Environ(), "GIT_TERMINAL_PROMPT=0", "GIT_CONFIG_NOSYSTEM=1",
		"GIT_CONFIG_GLOBAL=/dev/null", "GIT_CONFIG_COUNT=1",
		"GIT_CONFIG_KEY_0=http.https://github.com/.extraheader",
		"GIT_CONFIG_VALUE_0=Authorization: Basic "+base64.StdEncoding.EncodeToString([]byte("x-access-token:"+s.token)))
	cmd.WaitDelay = 5 * time.Second
	out, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("git %s: %w", args[0], err)
	}
	return strings.TrimSpace(string(out)), nil
}

func (s synchronizer) discover() ([]repository, error) {
	cache := filepath.Join(s.root, "repos.json")
	var cached []repository
	data, err := os.ReadFile(cache)
	valid := err == nil && json.Unmarshal(data, &cached) == nil
	if info, err := os.Stat(cache); valid && err == nil && time.Since(info.ModTime()) < 5*time.Minute {
		return cached, nil
	}
	repos, err := s.listRepos()
	if err != nil {
		if valid {
			log.Printf("Discovery failed; using previous list: %v", err)
			return cached, nil
		}
		return nil, err
	}
	data, err = json.Marshal(repos)
	if err != nil {
		return nil, err
	}
	if err := os.WriteFile(cache+".tmp", data, 0600); err != nil {
		return nil, err
	}
	return repos, os.Rename(cache+".tmp", cache)
}

func (s synchronizer) listRepos() ([]repository, error) {
	client := &http.Client{Timeout: 30 * time.Second}
	repos := []repository{}
	for page := 1; ; page++ {
		url := fmt.Sprintf("%s/user/repos?affiliation=owner&visibility=private&per_page=100&page=%d", s.api, page)
		req, err := http.NewRequest(http.MethodGet, url, nil)
		if err != nil {
			return nil, err
		}
		req.Header.Set("Authorization", "Bearer "+s.token)
		req.Header.Set("Accept", "application/vnd.github+json")
		req.Header.Set("X-GitHub-Api-Version", "2022-11-28")
		resp, err := client.Do(req)
		if err != nil {
			return nil, err
		}
		var batch []repository
		if resp.StatusCode != http.StatusOK {
			resp.Body.Close()
			return nil, fmt.Errorf("GitHub repository discovery: HTTP %d", resp.StatusCode)
		}
		err = json.NewDecoder(resp.Body).Decode(&batch)
		resp.Body.Close()
		if err != nil {
			return nil, err
		}
		for _, repo := range batch {
			if repo.Private && strings.EqualFold(repo.Owner.Login, owner) &&
				repoName.MatchString(repo.Name) && repo.Name != "." && repo.Name != ".." {
				repos = append(repos, repo)
			}
		}
		if len(batch) < 100 {
			return repos, nil
		}
	}
}

func (s synchronizer) syncRepo(repo repository) error {
	root := filepath.Join(s.root, "github.com", owner)
	path := filepath.Join(root, repo.Name)
	url := "https://github.com/" + owner + "/" + repo.Name + ".git"
	if _, err := os.Lstat(path); errors.Is(err, os.ErrNotExist) {
		// Publish only complete clones. Never expose the temporary clone.
		temp, err := os.MkdirTemp(s.root, ".clone-")
		if err != nil {
			return err
		}
		defer os.RemoveAll(temp)
		clone := filepath.Join(temp, "repo")
		if _, err := s.git("", "clone", "--quiet", "--", url, clone); err != nil {
			return err
		}
		if err := os.Rename(clone, path); err != nil {
			return err
		}
		log.Printf("Cloned %s", repo.Name)
	}
	// Only operate on real directories under the service-owned cache.
	for _, dir := range []string{path, filepath.Join(path, ".git")} {
		if info, err := os.Lstat(dir); err != nil || !info.IsDir() {
			return errors.New("not a regular clone")
		}
	}
	if _, err := s.git(path, "remote", "set-url", "origin", url); err != nil {
		return err
	}
	if _, err := s.git(path, "fetch", "--quiet", "--force", "--prune", "--tags",
		"origin", "+refs/heads/*:refs/remotes/origin/*"); err != nil {
		return err // Do not destroy anything when the remote cannot be fetched.
	}
	ref := "refs/remotes/origin/" + repo.DefaultBranch
	if _, err := s.git(path, "check-ref-format", ref); err != nil {
		return err
	}
	target, err := s.git(path, "rev-parse", "--verify", ref+"^{commit}")
	if err != nil {
		refs, listErr := s.git(path, "for-each-ref", "--format=%(refname)", "refs/remotes/origin/")
		if listErr == nil && refs == "" {
			// Empty remote: clear any staged additions and leave an empty tree.
			if _, err := s.git(path, "read-tree", "--empty"); err != nil {
				return err
			}
			_, err := s.git(path, "clean", "-ffdx", "--quiet")
			return err
		}
		return err
	}
	before, _ := s.git(path, "rev-parse", "HEAD")
	// This cache is disposable: remove ignored files and nested repos too.
	if _, err := s.git(path, "clean", "-ffdx", "--quiet"); err != nil {
		return err
	}
	if _, err := s.git(path, "reset", "--hard", "--quiet", target); err != nil {
		return err
	}
	if _, err := s.git(path, "checkout", "--force", "-B", repo.DefaultBranch, target); err != nil {
		return err
	}
	if _, err := s.git(path, "branch", "--set-upstream-to="+ref, "--", repo.DefaultBranch); err != nil {
		return err
	}
	if before != target {
		log.Printf("Updated %s", repo.Name)
	}
	return nil
}

func (s synchronizer) syncAll() error {
	lock, err := os.OpenFile(filepath.Join(s.root, "lock"), os.O_CREATE|os.O_RDWR, 0600)
	if err != nil {
		return err
	}
	defer lock.Close()
	if err := syscall.Flock(int(lock.Fd()), syscall.LOCK_EX|syscall.LOCK_NB); err != nil {
		if errors.Is(err, syscall.EWOULDBLOCK) {
			return nil
		}
		return err
	}
	defer syscall.Flock(int(lock.Fd()), syscall.LOCK_UN)
	repos, err := s.discover()
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Join(s.root, "github.com", owner), 0750); err != nil {
		return err
	}
	jobs := make(chan repository)
	var workers sync.WaitGroup
	var failures atomic.Int32
	for i := 0; i < 8; i++ {
		workers.Add(1)
		go func() {
			defer workers.Done()
			for repo := range jobs {
				if err := s.syncRepo(repo); err != nil {
					failures.Add(1)
					log.Printf("Failed %s: %v", repo.Name, err)
				}
			}
		}()
	}
	for _, repo := range repos {
		jobs <- repo
	}
	close(jobs)
	workers.Wait()
	if count := failures.Load(); count != 0 {
		return fmt.Errorf("%d repositories failed; see log above", count)
	}
	return nil
}

func main() {
	syscall.Umask(0027) // Sync account writes; reader group can only read/traverse.
	if len(os.Args) != 2 {
		log.Fatal("usage: github-sync STORAGE_ROOT (GitHub token on stdin)")
	}
	token, err := io.ReadAll(io.LimitReader(os.Stdin, 16384))
	if err != nil || strings.TrimSpace(string(token)) == "" {
		log.Fatal("missing GitHub token; run gh auth login --hostname github.com")
	}
	s := synchronizer{root: os.Args[1], token: strings.TrimSpace(string(token)), api: "https://api.github.com"}
	if err := s.syncAll(); err != nil {
		log.Fatal(err)
	}
}
