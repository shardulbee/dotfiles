# Minimal NixOS Configuration

A minimal, Omarchy-inspired NixOS setup with Hyprland, designed for simplicity and ease of use.

## Philosophy

- **Minimal**: Only essential packages and config
- **No home-manager**: Nix manages system packages, you manage your dotfiles
- **Aerospace-inspired**: Familiar keybindings from macOS
- **Raycast-like**: Super+Space for fuzzy launcher

## System Specs

Based on your desktop:
- Intel i5-9600K
- AMD RX 5700 XT
- 16GB RAM
- Btrfs filesystem with zram swap

## Installation

### 1. Install NixOS

Boot from NixOS installer and partition your disk:

```bash
# Partition (adjust /dev/nvme0n1 to your disk)
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 2GiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart primary btrfs 2GiB 100%

# Format
mkfs.fat -F 32 -n boot /dev/nvme0n1p1
mkfs.btrfs -L root /dev/nvme0n1p2

# Create btrfs subvolumes
mount /dev/nvme0n1p2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@pkg
umount /mnt

# Mount everything
mount -o subvol=@,compress=zstd,noatime /dev/nvme0n1p2 /mnt
mkdir -p /mnt/{boot,home,var/log,var/cache/pacman/pkg}
mount /dev/nvme0n1p1 /mnt/boot
mount -o subvol=@home,compress=zstd,noatime /dev/nvme0n1p2 /mnt/home
mount -o subvol=@log,compress=zstd,noatime /dev/nvme0n1p2 /mnt/var/log
mount -o subvol=@pkg,compress=zstd,noatime /dev/nvme0n1p2 /mnt/var/cache/pacman/pkg
```

### 2. Install the config

```bash
# Clone your dotfiles
git clone https://github.com/yourusername/dotfiles /mnt/home/shardul/dotfiles

# Copy config files
cp /mnt/home/shardul/dotfiles/nixos/configuration.nix /mnt/etc/nixos/
cp /mnt/home/shardul/dotfiles/nixos/hardware-configuration.nix /mnt/etc/nixos/

# Install
nixos-install

# Set password
nixos-enter --root /mnt -c 'passwd shardul'

# Reboot
reboot
```

### 3. Set up Hyprland config

After first boot:

```bash
mkdir -p ~/.config/hypr
mkdir -p ~/.config/waybar

cp ~/dotfiles/nixos/hyprland.conf ~/.config/hypr/hyprland.conf
cp ~/dotfiles/nixos/waybar-config.json ~/.config/waybar/config
cp ~/dotfiles/nixos/waybar-style.css ~/.config/waybar/style.css
```

## Keybindings

### Launcher
- **Super + Space**: Open launcher (wofi)

### Window Focus (Aerospace-style)
- **Alt + h/j/k/l**: Focus left/down/up/right

### Window Move
- **Alt + Shift + h/j/k/l**: Move window left/down/up/right

### Window Resize
- **Alt + Shift + -**: Shrink window
- **Alt + Shift + =**: Grow window

### Workspaces
- **Alt + 1-9,0**: Switch to workspace 1-10
- **Alt + Shift + 1-9,0**: Move window to workspace 1-10

### Window Management
- **Alt + Q**: Close window
- **Alt + F**: Fullscreen
- **Alt + Shift + Space**: Toggle floating

### Other
- **Super + Enter**: Open terminal (Ghostty)
- **Print**: Screenshot area (to clipboard)
- **Shift + Print**: Screenshot full screen (to clipboard)

## Customization

### Add packages

Edit `/etc/nixos/configuration.nix` and add packages to `environment.systemPackages`, then:

```bash
sudo nixos-rebuild switch
```

### Modify Hyprland config

Edit `~/.config/hypr/hyprland.conf` and reload Hyprland:

```bash
hyprctl reload
```

### Keep dotfiles separate

Your neovim, fish, git, etc configs in `~/dotfiles/.config/` are yours to manage.
Just symlink them:

```bash
ln -sf ~/dotfiles/.config/nvim ~/.config/nvim
ln -sf ~/dotfiles/.config/fish ~/.config/fish
# etc
```

## What's NOT managed by Nix

- Your dotfiles (neovim, fish, tmux, etc)
- Application-specific configs
- Development tools (use mise/asdf as you already do)

## What IS managed by Nix

- System packages
- System services (pipewire, networkmanager, etc)
- Window manager (Hyprland)
- Boot configuration
- Hardware drivers

## Updating

```bash
# Update system
sudo nixos-rebuild switch --upgrade

# Clean old generations
sudo nix-collect-garbage -d
```

## Tips

- The system is stateless - your configs in `/etc/nixos/` are the source of truth
- To try something temporarily: `nix-shell -p package-name`
- Your home directory and dotfiles are untouched by Nix
- Window management feels just like Aerospace on macOS
