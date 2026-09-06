#!/usr/bin/env bash
set -euo pipefail

state="$HOME/.local/state/sharchy-screen-record"

if [ -f "$state" ]; then
  read -r pid file < "$state"
  if kill -0 "$pid" 2>/dev/null; then
    kill -INT "$pid"
    while kill -0 "$pid" 2>/dev/null; do sleep 0.1; done
    wl-copy --type video/mp4 < "$file"
    rm -f "$state"
    notify-send "Screen recording saved and copied" "$file"
    exit 0
  fi
  rm -f "$state"
fi

geometry="$({
  hyprctl monitors -j | jq -r '.[] | "\(.x),\(.y) \(.width / .scale | floor)x\(.height / .scale | floor)"'
  hyprctl clients -j | jq -r '.[] | select(.mapped and (.hidden | not)) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
} | slurp)" || exit 0
mkdir -p "$HOME/Videos/Screen Recordings" "$(dirname "$state")"
file="$HOME/Videos/Screen Recordings/recording_$(date +%Y%m%d_%H%M%S).mp4"
wf-recorder -g "$geometry" -f "$file" >/dev/null 2>&1 &
printf '%s %s\n' "$!" "$file" > "$state"
notify-send "Screen recording started" "Press Cmd+Shift+5 again to stop"
