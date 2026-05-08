# dotfiles

Once you've installed Nix:

```sh
nix run nixpkgs#jujutsu -- git clone https://github.com/shardulbee/dotfiles ~/Documents/dotfiles
~/Documents/dotfiles/setup
```

To make fish your login shell, edit `/etc/shells` and put `which fish` there. Then run:

```sh
chsh -s "$(which fish)"
```

macOS apps/tools:

```sh
brew install trash qemu neurosnap/tap/zmx 1password 1password-cli ghostty google-chrome obsidian raycast slack spotify tailscale-app anki zed font-jetbrains-mono-nerd-font
```
