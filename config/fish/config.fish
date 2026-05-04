# Managing PATH
fish_add_path -gm "$HOME/bin"
fish_add_path -gm "$HOME/.npm-global/bin"
fish_add_path -gm "$HOME/.nix-profile/bin"
if test (uname) = Darwin
    fish_add_path -g -m --append /opt/homebrew/bin
end

# Use zed as EDITOR within Zed and not using Zed SSH
# Use neovim otherwise
if set -q ZED_TERM; and not set -q SSH_CONNECTION
    set -gx EDITOR "zed --wait"
else
    set -gx EDITOR "nvim"
end

# Shell integrations
command -q fzf; and fzf --fish | source
command -q atuin; and atuin init fish --disable-up-arrow | source
command -q zoxide; and zoxide init fish | source

# Machine-specific settings
test -f "$HOME/.config/fish/local.fish"; and source "$HOME/.config/fish/local.fish"
