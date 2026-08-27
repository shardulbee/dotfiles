# dotfiles

Personal machine setup.

```sh
./setup
```

## Linux / Omarchy

`./setup` installs the captured Omarchy setup on Linux:

- Hyprland input, keybindings, and look/feel overrides
- Linux Ghostty config and Alabaster themes
- Chromium Alt-click extension and flags
- Alabaster Omarchy light/dark themes
- user systemd timer for 7am/7pm light/dark switching

The large textured wallpapers are not checked in. They are regenerated from
`omarchy/bin/generate-alabaster-backgrounds` when ImageMagick's `magick` is
available.

## NixOS

Starter flake:

```sh
nix flake check
sudo nixos-rebuild switch --flake .#sharchy
```

Before installing NixOS, replace
`nixos/hosts/sharchy/hardware-configuration.nix` with the output of
`nixos-generate-config` on the target machine.
