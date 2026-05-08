# dotfiles

Once you've installed Nix:

```sh
nix run nixpkgs#jujutsu -- git clone https://github.com/shardulbee/dotfiles ~/Documents/dotfiles
~/Documents/dotfiles/setup
```

To make fish your login shell:

```sh
fish_path="$HOME/.nix-profile/bin/fish"
grep -qxF "$fish_path" /etc/shells || printf '%s\n' "$fish_path" | sudo tee -a /etc/shells
chsh -s "$fish_path"
```

macOS apps/tools:

```sh
brew install trash qemu neurosnap/tap/zmx 1password 1password-cli ghostty google-chrome obsidian raycast slack spotify tailscale-app anki zed font-jetbrains-mono-nerd-font
```
