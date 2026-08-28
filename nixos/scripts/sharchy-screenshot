#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/Pictures/Screenshots"
file="$HOME/Pictures/Screenshots/screenshot_$(date +%Y%m%d_%H%M%S).png"

case "${1:-region}" in
  region)
    geometry="$(slurp)" || exit 0
    grim -g "$geometry" - | tee "$file" | wl-copy --type image/png
    ;;
  fullscreen)
    grim - | tee "$file" | wl-copy --type image/png
    ;;
  *)
    echo "usage: sharchy-screenshot [region|fullscreen]" >&2
    exit 2
    ;;
esac

notify-send "Screenshot saved" "$file"
