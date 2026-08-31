# dotfiles

This repository contains the Nix configuration for the `sharchy` NixOS
workstation and the `macbook` macOS host. Home Manager installs the shared user
environment and application configuration. nix-darwin manages macOS settings
and Homebrew casks.

The flake assumes the repository is checked out at `~/Documents/dotfiles` for
the `shardul` user. Secrets and application state stay outside the Nix store.

## Apply the configuration

On macOS, install Determinate Nix and Homebrew, then run the initial activation:

```sh
sudo nix run nix-darwin -- switch --flake .#macbook
```

On NixOS, check and activate the `sharchy` configuration:

```sh
nix flake check
sudo nixos-rebuild switch --flake .#sharchy
```

After either initial setup, apply later changes with:

```sh
rebuild
```

On macOS, activation removes undeclared Homebrew formulae and casks. It does
not delete their application data.

## Repository layout

- `flake.nix` defines both hosts and the shared Home Manager configuration.
- `hosts/sharchy.nix` contains the NixOS hardware, desktop, and system services.
- `config/` contains editable configuration for shells, editors, terminals,
  Hyprland, Quickshell, and other desktop tools.
- `scripts/` contains commands used by the `sharchy` desktop for rebuilding,
  screenshots, themes, layouts, browser defaults, and shortcut help.
- `packages/` pins packages that are not taken directly from nixpkgs.

Command-line tools come from Nix. nix-darwin installs proprietary macOS apps as
Homebrew casks. `packages/playwriter.nix`, `packages/grok-bot.nix`, and
`packages/uberstat.nix` define locally packaged tools.
