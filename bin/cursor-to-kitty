#!/bin/bash

FILE_PATH="$1"
LINE_NUMBER="${2:-1}"

# Find Kitty socket
KITTY_SOCK="unix:/tmp/$(ls -1 /tmp/ | grep kitty | head -n 1)"
if [ -z "$KITTY_SOCK" ]; then
    echo "No Kitty socket found"
    exit 1
fi

if [ -n "$FILE_PATH" ]; then
    # Get absolute paths
    ABSOLUTE_FILE_PATH=$(realpath "$FILE_PATH")
    PROJECT_ROOT=$(git -C "$(dirname "$ABSOLUTE_FILE_PATH")" rev-parse --show-toplevel 2>/dev/null || echo "$(dirname "$ABSOLUTE_FILE_PATH")")
    
    # Find window with Neovim in project root
    WINDOW_ID=$(kitty @ --to "$KITTY_SOCK" ls | jq -r --arg root "$PROJECT_ROOT" '.[].tabs[].windows[] | select(.foreground_processes[] | select(.cmdline[]? | contains("nvim")) and .cwd == $root) | .id' | head -n 1)
    
    if [ -n "$WINDOW_ID" ]; then
        # Case 1: Existing Neovim window found
        kitty @ --to "$KITTY_SOCK" focus-window --match id:$WINDOW_ID
        kitty @ --to "$KITTY_SOCK" send-text --match id:$WINDOW_ID ":e +$LINE_NUMBER $(printf "%q" "$ABSOLUTE_FILE_PATH")"$'\n'
    else
        # Find any window in project root
        WINDOW_ID=$(kitty @ --to "$KITTY_SOCK" ls | jq -r --arg root "$PROJECT_ROOT" '.[].tabs[].windows[] | select(.cwd == $root) | .id' | head -n 1)
        
        if [ -n "$WINDOW_ID" ]; then
            # Case 2: Window with correct CWD found
            kitty @ --to "$KITTY_SOCK" focus-window --match id:$WINDOW_ID
            kitty @ --to "$KITTY_SOCK" send-text --match id:$WINDOW_ID "nvim '+$LINE_NUMBER' $(printf "%q" "$ABSOLUTE_FILE_PATH")"$'\n'
        else
            # Case 3: Create new window with correct CWD
            kitty @ --to "$KITTY_SOCK" launch --type tab --cwd "$PROJECT_ROOT" fish -c "nvim '+$LINE_NUMBER' '$(printf "%q" "$ABSOLUTE_FILE_PATH")'"
        fi
    fi
    open -a Kitty
else
    echo "No file path provided"
    exit 1
fi
