# Ship

- Validate with `nix flake check path:.`.
- Commit and push to `origin/main`. Dotfiles pushes do not deploy hosts.
- In `shardulbee/homelab`, run `nix flake update dotfiles`, review the resolved revision and diff, commit `flake.lock`, rebase, and push `main`.
- Verify Homelab's deployment on each online host; an offline workstation remains pending.
