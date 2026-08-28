# dotfiles

Personal macOS and NixOS configuration.

## macOS

```sh
./setup
```

The setup script links shared command-line configuration, installs the tools in
`mise-config.toml`, and applies the macOS application configuration.

## NixOS

The flake provides two independent systems:

- `sharchy`: Dell workstation with Hyprland and Helium
- `sharchy-vm`: ARM64 VMware guest with Niri and Chromium

```sh
nix flake check
sudo nixos-rebuild switch --flake .#sharchy
```

Host-specific hardware configuration lives under `nixos/hosts/`. Shared desktop
configuration, browser assets, and Ghostty configuration live under
`nixos/config/`.
