# Shipping

- Check: `nix flake check path:.` and relevant tests/linters.
- When asked to ship: commit, push reviewed changes to `origin/main`, deploy affected hosts, verify.
- Workflow: [.agents/ship.md](.agents/ship.md). Orb requirements live in `scripts/orb-deploy.py`; bootstrap in `config/{sharchy,turbogadget}-deploy.nix`.
- Do not deploy for commit/push-only requests, or deploy Sharchy for macOS-only changes.
