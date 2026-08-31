#!/usr/bin/env bash
set -euo pipefail

if pgrep -x fuzzel >/dev/null; then
  pkill -x fuzzel
  exit 0
fi

mode="$(cat "$HOME/.local/state/sharchy-theme" 2>/dev/null || echo light)"
case "$mode" in
  light|dark) ;;
  *) mode=light ;;
esac

exec fuzzel --config="$HOME/.config/fuzzel/$mode.ini" "$@"
