#!/usr/bin/env bash
set -euo pipefail

if pgrep -u "$UID" -f '/opt/helium/helium' >/dev/null; then exit 0; fi

shopt -s nullglob
for preferences in "$HOME"/.config/net.imput.helium/*/Preferences; do
  tmp="$(mktemp)"
  if jq '
    .helium.services.enabled = true |
    .helium.services.user_consented = true |
    .helium.services.ext_proxy = true |
    .vertical_tabs.enabled = true
  ' "$preferences" >"$tmp"; then
    chmod --reference="$preferences" "$tmp"
    mv "$tmp" "$preferences"
  else
    rm -f "$tmp"
  fi
done
