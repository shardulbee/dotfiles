if test (uname) = Linux
    # NixOS: wrappers must come first for setuid binaries (sudo, etc)
    fish_add_path --prepend /run/wrappers/bin
    fish_add_path $HOME/.local/bin $HOME/bin
    fish_add_path /run/current-system/sw/bin /etc/profiles/per-user/$USER/bin
else if test (uname) = Darwin
    fish_add_path $HOME/bin $HOME/.local/bin /opt/homebrew/bin
    set -x SECRETS_PATH $HOME/Library/Mobile\ Documents/com\~apple\~CloudDocs
end

set -gx EDITOR nvim
set -gx FZF_DEFAULT_CMD "fd -tf --hidden --exclude '.git' --no-require-git"
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_CMD"

command -q fzf; and fzf --fish | source
command -q mise; and mise activate fish | source
command -q atuin; and atuin init fish --disable-up-arrow | source
command -q zoxide; and zoxide init fish | source

if status is-interactive
    set fish_greeting
    bind \cf 'zi; commandline --function repaint'

    function vi -w nvim
        nvim $argv
    end
    function vim -w nvim
        nvim $argv
    end

    function ghostty_tab
        # Run a command in a new Ghostty tab
        set cmd (string join ' ' $argv)
        
        osascript -e '
        tell application "System Events"
            if not (exists process "Ghostty") then
                error "Ghostty is not running"
            end if
            if not (exists window 1 of process "Ghostty") then
                error "No Ghostty windows found"
            end if
        end tell
        
        tell application "Ghostty" to activate
        delay 0.2
        
        tell application "System Events"
            tell process "Ghostty"
                keystroke "t" using command down
                delay 0.3
                keystroke "'"$cmd"'"
                keystroke return
            end tell
        end tell
        ' 2>&1
    end

    function fish_prompt
        set -l last_status $status

        if test $last_status -eq 0
            set_color green
            echo -n "✓ "
        else
            set_color red
            echo -n "✘ $last_status "
        end

        set_color 55a630
        echo -n (prompt_pwd)
        set_color normal

        set_color normal
        echo
        echo -n '→ '
    end

    set -gx MANPAGER "sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"
end

# Machine-specific overrides
test -f ~/.config/fish/local.fish && source ~/.config/fish/local.fish
