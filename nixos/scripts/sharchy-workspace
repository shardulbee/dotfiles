#!/usr/bin/env bash
set -euo pipefail

workspace="${1:?usage: sharchy-workspace <workspace>}"

if hyprctl monitors -j | jq -e 'any(.[]; .specialWorkspace.name == "special:quake")' >/dev/null; then
  hyprctl dispatch togglespecialworkspace quake
fi

hyprctl dispatch workspace "$workspace"
