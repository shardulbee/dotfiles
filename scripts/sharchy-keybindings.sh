#!/usr/bin/env bash
cat <<'EOF' | "$HOME/.local/bin/sharchy-fuzzel" --dmenu --prompt='Keybindings > ' --width=66 --lines=34
Alt + Space                   App launcher
Super + Return                Terminal
Super + Shift + Return / B    Helium browser
Super + P                     1Password Quick Access
Super + Shift + P             1Password
Super + N                     Focus Obsidian space
Super + Tab                   Previous workspace
Super + Alt + K               This shortcut reference
Super + Alt + R               Rebuild NixOS
Super + Escape                Lock screen
Super + H/J/K/L               Focus left/down/up/right
Super + Shift + H/J/K/L       Move window left/down/up/right
Super + 1…9/0                 Focus workspace 1…10
Super + Shift + 1…9/0         Move window to workspace
Super + R                     Toggle split orientation
Super + -/=                   Decrease/increase width
Super + Shift + -/=           Decrease/increase height
Super + F                     Maximize window
Super + Shift + F             Fullscreen window
Super + Q                     Close window
Alt + Tab                     Previous workspace
Alt + C/V/X/A/Z               Copy/paste/cut/select all/undo
Alt + T/L/F                   New tab/address bar/find
Alt + N / Shift + N           New/incognito browser window
Alt + W / Shift + W           Close browser tab/window
Alt + Shift + T               Reopen browser tab
Alt + R / Shift + R           Reload/hard reload browser
Alt + 1…9                     Select browser tab
Alt + [/] / Shift + [/]       Back-forward / previous-next tab
Alt/Super + arrows            Line/word navigation
Super + Ctrl + T              Toggle light/dark theme
Alt + Shift + 3/4             Screenshot region/fullscreen
Alt + Shift + 5               Record: drag region or click window/screen
Print / Ctrl + Print          Screenshot region/fullscreen
Brightness and volume keys    Adjust display/audio
EOF
