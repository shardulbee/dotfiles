# Shipping

- Check: `nix flake check path:.` and relevant tests/linters.
- When asked to ship: commit, push reviewed changes to `origin/main`, deploy affected hosts, verify. Deploy both when changes impact both; otherwise only the affected host.
- Workflow: [.agents/ship.md](.agents/ship.md). Orb requirements live in `scripts/orb-deploy.py`; bootstrap in `config/{sharchy,turbogadget}-deploy.nix`.
- Do not deploy for commit/push-only requests.
