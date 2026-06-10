# Nix environment: PATH, NIX_PROFILES, NIX_SSL_CERT_FILE, XDG_DATA_DIRS.
# Its run-once guard is exported, so nested shells (tmux, etc.) skip it —
# that's why .nix-profile/bin is still pinned explicitly below.
if test -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
end

# PATH, highest priority first. -g: session-only; -m: move entries already
# on PATH so this order wins even if something else prepended them.
# Missing dirs are skipped, hence no existence/OS checks.
fish_add_path -gm "$HOME/.nix-profile/bin" "$HOME/.npm-global/bin" "$HOME/bin"
# Appended: brew is a fallback and must never shadow the above
fish_add_path -gm --append /opt/homebrew/bin

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

# Aliases
# Claude Code: auto mode + remote control by default, compact at 75% instead
# of 95%. Flags passed at the prompt come after --permission-mode, so they
# win. --remote-control stays last: its optional [name] arg would otherwise
# swallow a positional prompt.
function claude --wraps claude
    CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=75 command claude --permission-mode auto $argv --remote-control
end
