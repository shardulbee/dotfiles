#!/usr/bin/env bash
set -uo pipefail

state_dir="$HOME/.local/state"
log="$state_dir/sharchy-rebuild.log"
status_file="$state_dir/sharchy-rebuild-status"
mkdir -p "$state_dir"

exec 9>"$state_dir/sharchy-rebuild.lock"
if ! /run/current-system/sw/bin/flock -n 9; then exit 0; fi

printf 'running\n' > "$status_file"
trap 'printf "idle\n" > "$status_file"' EXIT

/run/wrappers/bin/pkexec --disable-internal-agent \
  /run/current-system/sw/bin/nixos-rebuild switch \
  --flake /home/shardul/Documents/dotfiles#sharchy >"$log" 2>&1
status=$?

if [ "$status" -eq 0 ]; then
  printf 'success\n' > "$status_file"
  sleep 2
elif [ "$status" -eq 126 ]; then
  printf 'idle\n' > "$status_file"
else
  printf 'failed\n' > "$status_file"
  sleep 5
fi

exit "$status"
