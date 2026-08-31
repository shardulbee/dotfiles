# dotfiles

Nix configuration for the `sharchy` NixOS workstation and `macbook` macOS host.

Expected checkout: `~/Documents/dotfiles`.

## Apply

```sh
# First macOS activation
sudo nix run nix-darwin -- switch --flake .#macbook

# NixOS
nix flake check
sudo nixos-rebuild switch --flake .#sharchy

# Later changes on either host
rebuild
```
