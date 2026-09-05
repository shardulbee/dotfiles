package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
	"testing"
	"time"
)

func TestMain(m *testing.M) {
	syscall.Umask(0027)
	os.Exit(m.Run())
}

func write(t *testing.T, path, content string) {
	t.Helper()
	if err := os.WriteFile(path, []byte(content), 0640); err != nil {
		t.Fatal(err)
	}
}

func testGit(t *testing.T, dir string, args ...string) string {
	t.Helper()
	cmd := exec.Command("git", append([]string{"-c", "user.name=Test", "-c",
		"user.email=test@example.com", "-c", "commit.gpgsign=false"}, args...)...)
	cmd.Dir = dir
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("git %v: %v: %s", args, err, out)
	}
	return strings.TrimSpace(string(out))
}

func fixture(t *testing.T) (synchronizer, repository, string, string) {
	t.Helper()
	base := t.TempDir()
	t.Setenv("HOME", base)
	t.Setenv("GIT_CONFIG_NOSYSTEM", "1")
	t.Setenv("GIT_CONFIG_GLOBAL", "/dev/null")
	seed := filepath.Join(base, "seed")
	testGit(t, base, "init", "-b", "main", seed)
	write(t, filepath.Join(seed, "file"), "original\n")
	write(t, filepath.Join(seed, ".gitignore"), "ignored\n")
	testGit(t, seed, "add", ".")
	testGit(t, seed, "commit", "-m", "initial")
	remote := filepath.Join(base, "remote.git")
	testGit(t, base, "clone", "--bare", seed, remote)
	testGit(t, seed, "remote", "add", "origin", remote)
	// Redirect the production GitHub URL to a real local bare repository.
	t.Setenv("GIT_CONFIG_PARAMETERS", "'url.file://"+remote+".insteadOf=https://github.com/shardulbee/example.git'")
	root := filepath.Join(base, "storage")
	if err := os.MkdirAll(filepath.Join(root, "github.com", owner), 0750); err != nil {
		t.Fatal(err)
	}
	return synchronizer{root: root, token: "test-secret"}, repository{Name: "example", DefaultBranch: "main"}, seed, remote
}

func TestCloneResetForcePushAndBranchChange(t *testing.T) {
	s, repo, seed, _ := fixture(t)
	path := filepath.Join(s.root, "github.com", owner, repo.Name)
	sync := func() {
		t.Helper()
		if err := s.syncRepo(repo); err != nil {
			t.Fatal(err)
		}
	}
	sync()
	initial := testGit(t, path, "rev-parse", "HEAD")
	// Even when GitHub has not changed, discard local commits and every kind of file.
	testGit(t, path, "checkout", "-b", "local")
	write(t, filepath.Join(path, "file"), "local commit\n")
	testGit(t, path, "commit", "-am", "local")
	write(t, filepath.Join(path, "file"), "local edit\n")
	write(t, filepath.Join(path, "ignored"), "ignored data")
	write(t, filepath.Join(path, "untracked"), "untracked data")
	testGit(t, path, "init", "nested")
	sync()
	if testGit(t, path, "rev-parse", "HEAD") != initial || testGit(t, path, "branch", "--show-current") != "main" {
		t.Fatal("did not restore the default branch")
	}
	for _, name := range []string{"ignored", "untracked", "nested"} {
		if _, err := os.Stat(filepath.Join(path, name)); !os.IsNotExist(err) {
			t.Fatalf("did not remove %s", name)
		}
	}
	if data, _ := os.ReadFile(filepath.Join(path, "file")); string(data) != "original\n" {
		t.Fatal("did not restore tracked content")
	}
	write(t, filepath.Join(seed, "file"), "upstream\n")
	testGit(t, seed, "commit", "-am", "upstream")
	testGit(t, seed, "push", "origin", "main")
	sync()
	if testGit(t, path, "rev-parse", "HEAD") != testGit(t, seed, "rev-parse", "HEAD") {
		t.Fatal("did not fetch new commits")
	}
	testGit(t, seed, "reset", "--hard", initial)
	testGit(t, seed, "push", "--force", "origin", "main")
	sync()
	if testGit(t, path, "rev-parse", "HEAD") != initial {
		t.Fatal("did not follow force push")
	}
	testGit(t, seed, "checkout", "-b", "next")
	write(t, filepath.Join(seed, "file"), "next branch\n")
	testGit(t, seed, "commit", "-am", "next")
	testGit(t, seed, "push", "origin", "next")
	repo.DefaultBranch = "next"
	sync()
	if testGit(t, path, "branch", "--show-current") != "next" {
		t.Fatal("did not follow changed default branch")
	}
	if err := filepath.Walk(path, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.Mode().Perm()&0027 != 0 {
			return fmt.Errorf("read-only group/private permissions violated at %s: %o", path, info.Mode().Perm())
		}
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	config, _ := os.ReadFile(filepath.Join(path, ".git", "config"))
	if strings.Contains(string(config), s.token) || strings.Contains(string(config), "extraheader") {
		t.Fatal("credential persisted to clone config")
	}
}

func TestFailedFetchPreservesCheckoutAndFailedCloneCleansUp(t *testing.T) {
	s, repo, _, remote := fixture(t)
	if err := s.syncRepo(repo); err != nil {
		t.Fatal(err)
	}
	if err := os.Rename(remote, remote+"-offline"); err != nil {
		t.Fatal(err)
	}
	path := filepath.Join(s.root, "github.com", owner, repo.Name)
	write(t, filepath.Join(path, "file"), "keep while offline")
	if err := s.syncRepo(repo); err == nil {
		t.Fatal("expected fetch failure")
	}
	if data, _ := os.ReadFile(filepath.Join(path, "file")); string(data) != "keep while offline" {
		t.Fatal("failed fetch changed checkout")
	}
	if err := os.RemoveAll(path); err != nil {
		t.Fatal(err)
	}
	if err := s.syncRepo(repo); err == nil {
		t.Fatal("expected clone failure")
	}
	if _, err := os.Stat(path); !os.IsNotExist(err) {
		t.Fatal("failed clone left destination")
	}
	temps, _ := filepath.Glob(filepath.Join(s.root, ".clone-*"))
	if len(temps) != 0 {
		t.Fatal("failed clone left temporary directories")
	}
}

func TestEmptyRepoPicksUpFirstCommit(t *testing.T) {
	s, repo, seed, remote := fixture(t)
	testGit(t, remote, "update-ref", "-d", "refs/heads/main")
	if err := s.syncRepo(repo); err != nil {
		t.Fatal(err)
	}
	path := filepath.Join(s.root, "github.com", owner, repo.Name)
	write(t, filepath.Join(path, "local"), "discard")
	testGit(t, path, "add", "local")
	if err := s.syncRepo(repo); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(filepath.Join(path, "local")); !os.IsNotExist(err) {
		t.Fatal("empty repo kept local files")
	}
	testGit(t, seed, "push", "origin", "main")
	if err := s.syncRepo(repo); err != nil {
		t.Fatal(err)
	}
	if testGit(t, path, "rev-parse", "HEAD") != testGit(t, seed, "rev-parse", "HEAD") {
		t.Fatal("did not pick up first commit")
	}
}

func TestWorkerFailuresAreReported(t *testing.T) {
	s, repo, _, remote := fixture(t)
	if err := os.RemoveAll(remote); err != nil {
		t.Fatal(err)
	}
	data, _ := json.Marshal([]repository{repo})
	write(t, filepath.Join(s.root, "repos.json"), string(data))
	if err := s.syncAll(); err == nil || !strings.Contains(err.Error(), "1 repositories failed") {
		t.Fatalf("expected worker failure, got %v", err)
	}
}

func TestDiscoveryPaginationFilteringCacheAndOffline(t *testing.T) {
	calls := 0
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		calls++
		if r.Header.Get("Authorization") != "Bearer test-secret" || r.URL.Query().Get("visibility") != "private" || r.URL.Query().Get("affiliation") != "owner" {
			t.Error("missing private repo authentication/filter")
		}
		if r.URL.Query().Get("page") == "1" {
			batch := make([]repository, 100)
			batch[0].Name, batch[0].Private, batch[0].Owner.Login = "private", true, owner
			batch[1].Name, batch[1].Private, batch[1].Owner.Login = "org", true, "other"
			batch[2].Name, batch[2].Private, batch[2].Owner.Login = "public", false, owner
			batch[3].Name, batch[3].Private, batch[3].Owner.Login = "../escape", true, owner
			json.NewEncoder(w).Encode(batch)
		} else {
			fmt.Fprint(w, `[{"name":"second","private":true,"owner":{"login":"shardulbee"}}]`)
		}
	}))
	defer server.Close()
	s := synchronizer{root: t.TempDir(), token: "test-secret", api: server.URL}
	repos, err := s.discover()
	if err != nil || len(repos) != 2 || repos[0].Name != "private" || repos[1].Name != "second" || calls != 2 {
		t.Fatalf("discovery: %+v, %v, calls=%d", repos, err, calls)
	}
	if _, err := s.discover(); err != nil || calls != 2 {
		t.Fatal("fresh cache made network request")
	}
	cache := filepath.Join(s.root, "repos.json")
	old := time.Now().Add(-6 * time.Minute)
	if err := os.Chtimes(cache, old, old); err != nil {
		t.Fatal(err)
	}
	server.Close()
	if repos, err := s.discover(); err != nil || len(repos) != 2 {
		t.Fatal("offline discovery did not preserve cached list")
	}
}

func TestConcurrentRunReturnsWithoutNetwork(t *testing.T) {
	s := synchronizer{root: t.TempDir(), api: "invalid"}
	lock, err := os.OpenFile(filepath.Join(s.root, "lock"), os.O_CREATE|os.O_RDWR, 0600)
	if err != nil {
		t.Fatal(err)
	}
	defer lock.Close()
	if err := syscall.Flock(int(lock.Fd()), syscall.LOCK_EX|syscall.LOCK_NB); err != nil {
		t.Fatal(err)
	}
	if err := s.syncAll(); err != nil {
		t.Fatal(err)
	}
}
