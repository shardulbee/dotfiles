# PATH, highest priority first. -g: session-only; -m: move entries already
# on PATH so this order wins even if something else prepended them.
# Missing dirs are skipped, hence no existence/OS checks.
fish_add_path -gm "$HOME/.local/bin" "$HOME/bin" /opt/homebrew/bin

# mise tools, env, and shims.
if command -q mise
    mise activate fish | source
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
command -q direnv; and direnv hook fish | source

# Machine-specific settings
test -f "$HOME/.config/fish/local.fish"; and source "$HOME/.config/fish/local.fish"

