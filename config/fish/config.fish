fish_add_path $HOME/bin $HOME/.npm-global/bin
test -d /opt/homebrew/bin; and fish_add_path /opt/homebrew/bin

if test -n "$ZED_TERM"; and test -z "$SSH_CONNECTION"
    set -gx EDITOR "zed --wait"
else
    set -gx EDITOR "nvim"
end

test -f ~/.config/secrets; and source ~/.config/secrets

command -q fzf; and fzf --fish | source
command -q atuin; and atuin init fish --disable-up-arrow | source
command -q zoxide; and zoxide init fish | source
