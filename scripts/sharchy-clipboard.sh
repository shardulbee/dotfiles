#!/usr/bin/env bash
set -euo pipefail

exec quickshell -c sharchy-clipboard ipc call clipboard toggle
