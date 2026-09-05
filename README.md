# dotfiles

Nix configuration for Sharchy (NixOS) and TurboGadget (`macbook`, macOS).
Checkout: `~/Documents/dotfiles`. Local updates: `rebuild`.

- First macOS activation: `sudo nix run nix-darwin -- switch --flake .#macbook`.
- Orb → Sharchy: `nix run .#orb-deploy-sharchy` ([script](scripts/orb-deploy.py)).
- Orb → TurboGadget: `nix run .#orb-deploy-turbogadget` ([script](scripts/orb-deploy.py), [bootstrap](config/turbogadget-deploy.nix)).
- Read-only GitHub cache: `gr` to browse, `github-checkouts-refresh` to refresh ([configuration](config/github-sync.nix), [sync logic](packages/github-sync/main.go)).

Check: `nix flake check path:.`.
