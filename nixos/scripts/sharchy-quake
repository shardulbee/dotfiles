#!/usr/bin/env bash
set -euo pipefail

if hyprctl clients -j | jq -e 'any(.[]; .class == "com.sharchy.quake")' >/dev/null; then
  hyprctl dispatch togglespecialworkspace quake
  exit
fi

hyprctl dispatch exec 'ghostty --class=com.sharchy.quake'
for _ in {1..20}; do
  hyprctl clients -j | jq -e 'any(.[]; .class == "com.sharchy.quake")' >/dev/null && break
  sleep 0.05
done

if ! hyprctl monitors -j | jq -e 'any(.[]; .specialWorkspace.name == "special:quake")' >/dev/null; then
  hyprctl dispatch togglespecialworkspace quake
fi
