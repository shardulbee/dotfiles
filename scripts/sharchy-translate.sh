#!/usr/bin/env bash
set -euo pipefail

notify() {
  notify-send --app-name="Translate" "$1" "${2:-}"
}

wl-copy --clear
wtype -M ctrl -k c -m ctrl
sleep 0.1
selection="$(wl-paste --no-newline 2>/dev/null || true)"
if [[ -z "$selection" ]]; then
  notify "Nothing selected"
  exit 1
fi

if [[ -z "${FIREWORKS_API_KEY:-}" ]]; then
  notify "Translation failed" "FIREWORKS_API_KEY is unavailable"
  exit 1
fi

quickshell -p /home/shardul/.config/quickshell/translate.qml &
overlay_pid=$!
cleanup() {
  if [[ -n "${overlay_pid:-}" ]]; then
    kill "$overlay_pid" 2>/dev/null || true
    wait "$overlay_pid" 2>/dev/null || true
    overlay_pid=
  fi
}
trap cleanup EXIT

payload="$(jq -n --arg text "$selection" '{
  model: "accounts/fireworks/models/deepseek-v4-flash-0731",
  reasoning_effort: "none",
  temperature: 0.2,
  max_tokens: 4096,
  messages: [
    {
      role: "system",
      content: "Translate into natural contemporary French as written in Québec. Use a neutral written register with Québec vocabulary and phrasing, but no slang or chumminess. When the source register is ambiguous, use vous rather than tu. Preserve the meaning, tone, names, formatting, and paragraph breaks. Return only the translation."
    },
    { role: "user", content: $text }
  ]
}')"

if ! response="$(curl --silent --show-error --fail-with-body --max-time 30 \
  https://api.fireworks.ai/inference/v1/chat/completions \
  -H "Authorization: Bearer $FIREWORKS_API_KEY" \
  -H "Content-Type: application/json" \
  --data-binary "$payload")"; then
  notify "Translation failed" "Fireworks did not return a response"
  exit 1
fi

if ! translation="$(jq -er '.choices[0].message.content | strings | select(length > 0)' <<<"$response")"; then
  notify "Translation failed" "Fireworks returned an invalid response"
  exit 1
fi

printf %s "$translation" | wl-copy
sleep 0.1
wtype -M ctrl -k v -m ctrl
cleanup
notify "Translation inserted"
