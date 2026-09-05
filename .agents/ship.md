# Ship

- Validate with `nix flake check path:.` and relevant lint/build checks.
- Commit reviewed changes, publish to `origin/main`, and confirm clean HEAD is
  exactly current `origin/main`. Stop for review if main moved.
- Deploy only affected hosts: `nix run .#orb-deploy-sharchy` or
  `nix run .#orb-deploy-turbogadget`. Shared changes may affect both.
- First installation or an installed-helper limitation needs local/admin
  activation. Follow [Sharchy](../config/sharchy-deploy.nix) or
  [TurboGadget](../config/turbogadget-deploy.nix) bootstrap instructions.
- Verify the reported revision and system against `/run/current-system` via
  personal/admin access, then check affected services. A build alone is not success.
- Commit/push-only requests do not authorize deployment. Never deploy an unrelated
  host, including Sharchy for macOS-only changes.
