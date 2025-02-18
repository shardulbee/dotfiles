#!/bin/bash

# Exit on error. Erroring pipes fail the script. Undefined vars fail the script. Print commands before executing.
set -euxo pipefail

# 1. Install Homebrew if not already installed
if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    BREW_PATH="/opt/homebrew/bin/brew"

    # Initialize Homebrew in current session
    eval "$($BREW_PATH shellenv)"
fi

# 2. Install all packages from Brewfile
echo "Installing Homebrew packages..."
brew bundle install --file Brewfile.work

# 4. Set macOS defaults

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

# 5. Enable Touch ID for sudo
if ! grep -q "pam_tid.so" /etc/pam.d/sudo; then
    echo "Enabling Touch ID for sudo..."
    sudo sed -i '' '2i\
auth       sufficient     pam_tid.so
' /etc/pam.d/sudo
fi

# 6. Set up dotfiles with stow if directory exists
if [[ -d "$HOME/dotfiles" ]]; then
    echo "Linking dotfiles..."
    cd "$HOME/dotfiles"
    stow --ignore=.DS_Store -R --no-folding --dotfiles --target="$HOME" home
fi

# 7. Set up Fish as default shell
FISH_PATH="$(brew --prefix)/bin/fish"
if ! grep -q "$FISH_PATH" /etc/shells; then
    echo "Adding Fish to allowed shells..."
    echo "$FISH_PATH" | sudo tee -a /etc/shells
fi

if [[ "$SHELL" != "$FISH_PATH" ]]; then
    echo "Setting Fish as default shell..."
    chsh -s "$FISH_PATH"
fi

# Restart affected applications
echo "Restarting affected applications..."
killall Dock || true
killall Finder || true
killall SystemUIServer || true

echo "Setup complete! Some changes may require a logout/restart to take effect."
