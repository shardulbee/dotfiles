#!/bin/bash

# Exit on error. Erroring pipes fail the script. Undefined vars fail the script. Print commands before executing.
set -euxo pipefail

# 1. Install Homebrew if not already installed
if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    BREW_PATH="/opt/homebrew/bin/brew"

    # Add to .zprofile for login shell environment setup
    if ! grep -q "brew shellenv" "$HOME/.zprofile" 2>/dev/null; then
        echo "# Homebrew environment setup" >> "$HOME/.zprofile"
        echo "eval \"\$($BREW_PATH shellenv)\"" >> "$HOME/.zprofile"
    fi

    # Add to .zshrc for interactive shell setup
    if ! grep -q "brew shellenv" "$HOME/.zshrc" 2>/dev/null; then
        echo "# Homebrew environment setup" >> "$HOME/.zshrc"
        echo "eval \"\$($BREW_PATH shellenv)\"" >> "$HOME/.zshrc"
    fi

    # Initialize Homebrew in current session
    eval "$($BREW_PATH shellenv)"
fi

# 2. Install packages
# Note: We let brew handle idempotency for package installation
echo "Installing Homebrew packages..."
PACKAGES=(
    "zig"
    "nodejs"
    "neovim"
    "git"
    "fd"
    "jq"
    "bat"
    "gh"
    "ripgrep"
    "trash"
    "zoxide"
    "git-delta"
    "fzf"
    "fish"
    "asdf"
    "direnv"
    "stow"
    "lowdown"
)

brew install "${PACKAGES[@]}"

# 3. Install casks
# Note: We let brew handle idempotency for cask installation
echo "Installing Homebrew casks..."
CASKS=(
    "1password"
    "hammerspoon"
    "google-chrome"
    "raycast"
    "spotify"
    "zoom"
    "zed"
    "karabiner-elements"
    "obsidian"
    "zwift"
    "tailscale"
    "vlc"
    "cleanshot"
    "arq"
    "fantastical"
    "google-drive"
    "ghostty"
    "nikitabobko/tap/aerospace"
    "cursor"
)

brew install --cask "${CASKS[@]}"

# 6. Set up Fish shell
# Only modify /etc/shells if fish isn't already in there
if ! grep -q "$(which fish)" /etc/shells; then
    echo "Adding Fish to allowed shells..."
    echo "$(which fish)" | sudo tee -a /etc/shells
fi

# 7. Set up hostname
# Only change hostname if it's different
DESIRED_HOSTNAME="turbochardo"
CURRENT_HOSTNAME=$(hostname)
if [[ "$CURRENT_HOSTNAME" != "$DESIRED_HOSTNAME" ]]; then
    echo "Setting hostname to $DESIRED_HOSTNAME..."
    sudo scutil --set ComputerName "$DESIRED_HOSTNAME"
    sudo scutil --set HostName "$DESIRED_HOSTNAME"
    sudo scutil --set LocalHostName "$DESIRED_HOSTNAME"
fi

# 8. Set macOS defaults

# Keyboard
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
defaults write NSGlobalDomain "com.apple.keyboard.fnState" -bool false

# Trackpad
defaults write NSGlobalDomain "com.apple.mouse.tapBehavior" -int 1
defaults write NSGlobalDomain "com.apple.trackpad.trackpadCornerClickBehavior" -int 1

# Dock
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock mineffect -string "scale"
defaults write com.apple.dock launchanim -bool false
defaults write com.apple.dock expose-animation-duration -float 0.0
defaults write com.apple.dock orientation -string "bottom"
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock static-only -bool true

# Finder
defaults write com.apple.finder CreateDesktop -bool false
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder ShowPathbar -bool true

# System
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
defaults write com.apple.menuextra.clock Show24Hour -bool true

# 9. Enable Touch ID for sudo
# Only modify if pam_tid.so isn't already in there
if ! grep -q "pam_tid.so" /etc/pam.d/sudo; then
    echo "Enabling Touch ID for sudo..."
    sudo sed -i '' '2i\
auth       sufficient     pam_tid.so
' /etc/pam.d/sudo
fi

# Only try to stow if dotfiles directory exists
if [[ -d "$HOME/dotfiles" ]]; then
    echo "Linking dotfiles..."
    cd "$HOME/dotfiles"
    stow --ignore=.DS_Store -R --no-folding --dotfiles --target="$HOME" home
fi

# Restart affected applications only if we made changes
# Note: These are idempotent, so it's safe to run them always
echo "Restarting affected applications..."
killall Dock || true
killall Finder || true
killall SystemUIServer || true

echo "Setup complete! Some changes may require a logout/restart to take effect."
