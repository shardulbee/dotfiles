#!/usr/bin/env bash
set -euo pipefail

workspace_json="$(hyprctl activeworkspace -j)"
workspace_id="$(jq -r '.id' <<<"$workspace_json")"
workspace_name="$(jq -r '.name' <<<"$workspace_json")"
current_layout="$(jq -r '.tiledLayout' <<<"$workspace_json")"

if [[ "$current_layout" == "scrolling" ]]; then
  new_layout="dwindle"
else
  new_layout="scrolling"
fi

if (( workspace_id < 0 )); then
  workspace="name:$workspace_name"
else
  workspace="$workspace_id"
fi

hyprctl eval "hl.workspace_rule({ workspace = \"$workspace\", layout = \"$new_layout\" })" >/dev/null
notify-send -u low "Workspace layout: $new_layout"
