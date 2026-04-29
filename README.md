# dotfiles

Run `./setup`. It also bootstraps fish paths and the npm global prefix. You might need to run one of these commands on a new machine

- `grep -qx "$(which fish)" /etc/shells || echo "$(which fish)" | sudo tee -a /etc/shells`
- `chsh -s $(which fish)`

On Mac:

- `sudo scutil --set ComputerName "<name>"`
- `sudo scutil --set HostName "<name>"`
- `sudo scutil --set LocalHostName "<name>"`
