# Shipping

- Check: `nix flake check path:.` and relevant tests/linters.
- When asked to ship: commit, push reviewed changes to `origin/main`, deploy affected hosts, verify.
- Orb commands: `nix run .#orb-deploy-sharchy` / `nix run .#orb-deploy-turbogadget`; requirements live in those scripts.
- Do not deploy for commit/push-only requests, or deploy Sharchy for macOS-only changes.
