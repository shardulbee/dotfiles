fish_add_path $HOME/bin $HOME/.local/bin /run/current-system/sw/bin /etc/profiles/per-user/$USER/bin /opt/homebrew/bin

set -gx EDITOR nvim
set -gx FZF_DEFAULT_CMD "fd -tf --hidden --exclude '.git' --no-require-git"
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_CMD"

command -q fzf; and fzf --fish | source
command -q mise; and mise activate fish | source
command -q direnv; and direnv hook fish | source
command -q atuin; and atuin init fish --disable-up-arrow | source
command -q zoxide; and zoxide init fish | source
command -q orb; and source ~/.orbstack/shell/init2.fish 2>/dev/null

if status is-interactive
    set fish_greeting
    bind \cf 'zi; commandline --function repaint'

    function vi -w nvim
        nvim $argv
    end
    function vim -w nvim
        nvim $argv
    end
    function rm -w trash
        trash $argv
    end
    function rmfrfr -w rm
        rm $argv
    end

    function select_changeset
        set -l changesets (jj log -r 'all()' --no-graph --no-pager --color=always -T 'builtin_log_oneline' -n100 | fzf --reverse --ansi --accept-nth=1 --prompt="Select changeset: ")
        if test -z "$changesets"
            echo "Cancelled: No changeset selected" 1>&2
            return 1
        end
        echo $changesets
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

    function fish_title
        set -l cwd (path basename (pwd))
        if test -z "$cwd"
            set cwd /
        end
        set -l cmd (status current-command)
        if test -n "$cmd"
            echo "$cmd - $cwd"
        else
            echo $cwd
        end
    end

    set -gx MANPAGER "sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"
end
