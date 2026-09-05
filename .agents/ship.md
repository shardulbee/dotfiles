# Ship

- Validate with `nix flake check path:.` and relevant lint/build checks.
- Commit reviewed changes, publish to `origin/main`, and confirm clean HEAD is
  exactly current `origin/main`. Stop for review if main moved.
- Deploy both hosts when changes impact both: `nix run .#orb-deploy-sharchy` and
  `nix run .#orb-deploy-turbogadget`. Otherwise deploy only the affected host.
  Respect explicit host limits; do not deploy hosts unaffected by the changes.
- First installation or an installed-helper limitation needs local/admin
  activation. Follow [Sharchy](../config/sharchy-deploy.nix) or
  [TurboGadget](../config/turbogadget-deploy.nix) bootstrap instructions.
- Verify the reported revision and system against `/run/current-system` via
  personal/admin access, then check affected services. A build alone is not success.
- Commit/push-only requests do not authorize deployment.
