# dotfiles

Personal machine setup.

## Install

```sh
jj git clone https://github.com/shardulbee/dotfiles dotfiles
./dotfiles/setup
```

## Check

```sh
./dotfiles/setup --check
```

## What setup does

- resolves links relative to the `setup` script location
- installs Brewfile apps with `brew bundle` on macOS
- links dotfiles into `~/.config`, `~/.pi`, `~/.codex`, `~/.agents`, and `~/bin`
- refuses to overwrite real files
- installs CLI tools with `mise`

## Update

```sh
cd dotfiles
jj git fetch
jj rebase -b @ -o main
./setup
```

## Assumptions

- Homebrew owns GUI apps and `fish` on macOS
- `mise` owns CLI tools everywhere
- generated Pi TypeScript files stay local and ignored
