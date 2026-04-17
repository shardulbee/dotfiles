# dotfiles

Run `./setup`. You might need to run one of these commands on a new machine

- `grep -qx "$(which fish)" /etc/shells || echo "$(which fish)" | sudo tee -a /etc/shells`
- `chsh -s $(which fish)`
- `set -U fish_greeting`
- `sudo scutil --set ComputerName "<name>"`
- `sudo scutil --set HostName "<name>"`
- `sudo scutil --set LocalHostName "<name>"`

On machines where `node` is managed by Nix and you want to install npm packages globally, run the following

```
mkdir -p "$HOME/.npm-global/bin"
printf 'prefix=%s/.npm-global\n' "$HOME" > "$HOME/.npmrc"
```
