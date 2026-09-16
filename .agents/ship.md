# Ship

- Validate with `nix flake check path:.` and relevant lint/build checks.
- Commit reviewed changes, publish to `origin/main`, and confirm clean HEAD is
  exactly current `origin/main`. Stop for review if main moved.
- The `Deploy` GitHub Actions workflow deploys Sharchy, then TurboGadget.
  Confirm it succeeds; do not run another deployment concurrently.
- First installation or an installed-helper limitation needs local/admin
  activation. Follow [Sharchy](../config/sharchy-deploy.nix) or
  [TurboGadget](../config/turbogadget-deploy.nix) bootstrap instructions.
- Verify each reported system store path against `/run/current-system` via
  personal/admin access, then check affected services. A build alone is not success.
