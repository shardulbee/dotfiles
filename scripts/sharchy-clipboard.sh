#!/usr/bin/env bash
set -euo pipefail

if systemctl --user is-active --quiet sharchy-clipboard-ui.service; then
  exec systemctl --user stop sharchy-clipboard-ui.service
else
  exec systemctl --user start sharchy-clipboard-ui.service
fi
