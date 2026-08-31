#!/usr/bin/env bash
set -euo pipefail

lock="${XDG_RUNTIME_DIR:-/run/user/$UID}/fuzzel-${WAYLAND_DISPLAY:-wayland-1}.lock"
exec 9>"$lock"
if ! flock -n 9; then
  pkill -x fuzzel
  exit 0
fi
if [ "${1:-}" = --close-only ]; then exit 0; fi
flock -u 9

mode="$(cat "$HOME/.local/state/sharchy-theme" 2>/dev/null || echo light)"
case "$mode" in
  light|dark) ;;
  *) mode=light ;;
esac

exec fuzzel --config="$HOME/.config/fuzzel/$mode.ini" "$@"
