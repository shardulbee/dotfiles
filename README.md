# dotfiles

## New machine

Install Nix.

Linux:

```sh
curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
. ~/.nix-profile/etc/profile.d/nix.sh
```

macOS:

```sh
sh <(curl -L https://nixos.org/nix/install) --daemon
```

Enable flakes:

```sh
mkdir -p ~/.config/nix
printf 'experimental-features = nix-command flakes\n' >> ~/.config/nix/nix.conf
```

Clone, install CLI tools, link config:

```sh
git clone https://github.com/shardulbee/dotfiles ~/dotfiles
cd ~/dotfiles
nix profile install .#dev
./setup
```

Update later:

```sh
cd ~/dotfiles
git pull
nix profile upgrade dev
./setup
```

## Shell

Optional:

```sh
grep -qx "$(which fish)" /etc/shells || echo "$(which fish)" | sudo tee -a /etc/shells
chsh -s "$(which fish)"
```

## Mac name

```sh
sudo scutil --set ComputerName "<name>"
sudo scutil --set HostName "<name>"
sudo scutil --set LocalHostName "<name>"
```
