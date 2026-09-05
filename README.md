# dotfiles

Nix configuration for the `sharchy` NixOS workstation and `macbook` macOS host.

Expected checkout: `~/Documents/dotfiles`.

## Apply

```sh
# First macOS activation
sudo nix run nix-darwin -- switch --flake .#macbook

# NixOS
nix flake check
sudo nixos-rebuild switch --flake .#sharchy

# Later changes on either host
rebuild
```

## Deploy Sharchy from an Amp orb

The orb must have `TAILSCALE_CLIENT_ID` and `TAILSCALE_AUDIENCE` set for
the dotfiles project's Tailscale workload identity. Its
`SHARCHY_DEPLOY_SSH_KEY` secret authenticates standard OpenSSH after Tailscale
admits the short-lived deploy node. Push `main`, then deploy that exact commit:

```sh
git push origin HEAD
nix run .#deploy-sharchy
```

The deployment joins Tailscale as a short-lived `tag:amp-dotfiles-deploy`
node, connects to Sharchy as `shardul` over standard OpenSSH, and rebuilds the
exact pushed commit. Local and orb-triggered Sharchy rebuilds share
`/run/lock/sharchy-deploy.lock`.

## Read-only GitHub checkouts

Private repositories owned by `shardulbee` appear automatically under
`~/.cache/checkouts/github.com/shardulbee/<repo>`. Run the standalone `gr` command
from any shell for an fzf picker that opens `nvim .` in the selected repo, or
`gr dotfiles` to start with a search. Quitting Neovim starts your default shell
from `$SHELL` in that repo. This is a new shell because an executable cannot change
its parent's directory; exit it to return to the original shell. Cancelling the
picker does not open Neovim or a new shell.

The updater fetches eight repos at a time on a 30-second timer, with no overlapping
runs. Initial clones and slow networks can take longer. It discovers new repos
and default-branch changes every five minutes. These are full Git clones, not
mounts or shallow snapshots. It does not install dependencies, run repository
hooks, initialize submodules, or download Git LFS objects.

**This is a disposable cache, not a development directory.** Each successful
refresh restores GitHub's default branch, follows force pushes, and deletes local
edits, untracked files, ignored files, and nested repositories. Failed fetches
leave the existing checkout alone. Repos that disappear from discovery are kept
locally but no longer refreshed.

The `github-sync` system account owns the files. The `github-checkouts` group gives
`shardul` read/traverse access only, so normal editor saves, chmod, deletes, and
local agents cannot change the contents. Sudo is deliberately outside this
protection. The home path is a symlink into `/var/lib/github-checkouts` on Linux
or `/var/db/github-checkouts` on macOS. Your user can remove the link, but cannot
delete its contents. Rebuild to restore a removed link.

After applying the configuration, log out and back in once for the new reader
group. On macOS the hidden sync account and reader group reserve UID/GID 499.
The sync uses the existing `shardulbee` GitHub CLI login. If needed, run
`gh auth login --hostname github.com` with access to your private repositories.
The user service pipes the token to the writer account using a narrowly scoped
sudo rule; the updater never saves it in the clones or a separate token file.

```sh
github-checkouts-refresh               # Refresh now on either platform
systemctl --user status github-sync.timer  # Sharchy schedule
journalctl --user -u github-sync.service    # Sharchy logs
tail ~/Library/Logs/github-sync.log         # macOS logs
```

The updater uses Go's standard library plus Git. Nix packages both, with `gh`
supplying authentication from the user session. To check the Go code:

```sh
cd packages/github-sync
go test -race ./...
go vet ./...
```
