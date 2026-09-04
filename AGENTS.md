# Sharchy deployment

When the user asks to ship changes that affect Sharchy, shipping includes the
deployment, not only a Git push:

1. Run `nix flake check path:.` and applicable linters or static checks. The
   supervised Attic store watcher uploads new orb-built paths to the private
   Sharbox cache automatically when `ATTIC_TOKEN` is configured.
2. Commit and push the exact reviewed changes to `origin/main`.
3. Run `nix run .#deploy-sharchy` and confirm Sharchy builds and switches to
   that revision successfully.

Do not deploy Sharchy for changes that affect only the macOS configuration.
Do not deploy when the user asks only to commit or push.
