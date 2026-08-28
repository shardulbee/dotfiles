#!/usr/bin/env bash
set -euo pipefail

state="$HOME/.local/state/sharchy-theme"
mkdir -p "$(dirname "$state")"
mode="${1:-toggle}"
if [ "$mode" = scheduled ]; then
  hour=$((10#$(date +%H)))
  if (( hour >= 19 || hour < 7 )); then mode=dark; else mode=light; fi
elif [ "$mode" = toggle ]; then
  current="$(cat "$state" 2>/dev/null || echo light)"
  if [ "$current" = light ]; then mode=dark; else mode=light; fi
fi
case "$mode" in
  light|dark)
    echo "$mode" > "$state"
    if [ -w /run/sharchy/theme ]; then printf '%s\n' "$mode" > /run/sharchy/theme; fi
    dconf write /org/gnome/desktop/interface/color-scheme "'prefer-$mode'" || true
    systemctl --user restart sharchy-wallpaper.service
    ;;
  *) exit 2 ;;
esac
notify-send "Sharchy theme" "$mode mode" || true
