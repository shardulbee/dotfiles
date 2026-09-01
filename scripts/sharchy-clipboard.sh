#!/usr/bin/env bash
set -euo pipefail

selection="$(
  cliphist list |
    "$HOME/.local/bin/sharchy-fuzzel" \
      --dmenu \
      --prompt='  ' \
      --placeholder='Search clipboard…'
)"

if [ -n "$selection" ]; then
  printf '%s\n' "$selection" | cliphist decode | wl-copy
  sleep 0.15
  wtype -M shift -k Insert -m shift 2>/dev/null || true
fi
