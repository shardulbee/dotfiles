# Minimal NixOS

Absolute minimum NixOS config with Niri.

## Setup

```bash
# Copy to /etc/nixos/
sudo cp configuration.nix /etc/nixos/

# Rebuild
sudo nixos-rebuild switch

# Copy niri config
mkdir -p ~/.config/niri
cp niri.kdl ~/.config/niri/config.kdl
```

## What's included

- Niri (scrollable-tiling Wayland compositor)
- Fuzzel (launcher)
- Ghostty (terminal)
- fish, git, jj, neovim, ripgrep, fd, fzf

## Keys

- **Super + Space**: Launch apps
- **Super + Return**: Terminal
- **Super + Q**: Close window
- **Super + hjkl**: Navigate windows
- **Super + Shift + hjkl**: Move windows
- **Super + 1-9**: Switch workspace
- **Super + Shift + 1-9**: Move to workspace
- **Super + F**: Fullscreen
- **Super + ,**: Stack windows
- **Super + .**: Unstack windows

## Philosophy

Nix manages system packages only. Your dotfiles are yours.

```bash
ln -sf ~/dotfiles/.config/nvim ~/.config/nvim
ln -sf ~/dotfiles/.config/fish ~/.config/fish
```

## Add packages

Edit `/etc/nixos/configuration.nix`, add to `environment.systemPackages`, then:

```bash
sudo nixos-rebuild switch
```
