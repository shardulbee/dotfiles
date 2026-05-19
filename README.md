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

macOS tools:

```sh
brew install \
  trash \
  qemu \
  neurosnap/tap/zmx
```

macOS apps:

```sh
brew install --cask \
  1password \
  1password-cli \
  codex-app \
  ghostty \
  google-chrome \
  obsidian \
  raycast \
  slack \
  spotify \
  tailscale-app \
  anki \
  zed \
  font-jetbrains-mono-nerd-font
```
