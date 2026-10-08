# Ship

- Validate with `nix flake check path:.`.
- Commit and push to `origin/main`; `.github/workflows/deploy.yml` redeploys every host.
- Done only when that Deploy run succeeds: `gh run watch <id> --exit-status`. The sharchy job may fail while the workstation sleeps.
- Retry with `gh run rerun <id> --failed`.
