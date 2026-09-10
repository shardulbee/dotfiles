#!/usr/bin/env bash
set -uo pipefail

state_dir="$HOME/.local/state"
log="$state_dir/sharchy-rebuild.log"
mkdir -p "$state_dir"

exec 9>"$state_dir/sharchy-rebuild.lock"
if ! /run/current-system/sw/bin/flock -n 9; then exit 0; fi

/run/wrappers/bin/pkexec --disable-internal-agent \
  /run/current-system/sw/bin/nixos-rebuild switch \
  --flake /home/shardul/Documents/dotfiles#sharchy >"$log" 2>&1
