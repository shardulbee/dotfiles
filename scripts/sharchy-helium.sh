#!/usr/bin/env bash
set -euo pipefail

if ! pgrep -u "$UID" -f '/opt/helium/helium' >/dev/null; then
  "$HOME/.local/bin/sharchy-helium-defaults"
fi
exec /run/current-system/sw/bin/helium "$@"
