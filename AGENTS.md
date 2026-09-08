# Shipping

- Check: `nix flake check path:.` and relevant tests/linters.
- When asked to ship: commit and push reviewed changes to `origin/main`; GitHub Actions deploys both hosts sequentially. Verify both.
- Workflow: [.agents/ship.md](.agents/ship.md). Bootstrap lives in `config/{sharchy,turbogadget}-deploy.nix`.
