# Dotfiles

What works for me will not work for you. How to get up and running:

1. `xcode-select --install && softwareupdate --install-rosetta`
2. `sudo scutil --set HostName turbochardo && sudo scutil --set LocalHostName turbochardo && sudo scutil --set ComputerName turbochardo`
3. `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install`
4. `nix run nix-darwin -- switch --flake github:shardulbee/dotfiles`
