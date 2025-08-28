# vim: ts=2 sw=2 et
fish_add_path $HOME/bin $HOME/.local/bin /run/current-system/sw/bin /etc/profiles/per-user/$USER/bin /opt/homebrew/bin

set -gx EDITOR 'nvim'
set -gx SECRETS_PATH "$HOME/gdrive"
set -gx FZF_DEFAULT_CMD "fd -tf --hidden --exclude '.git' --no-require-git"
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_CMD"

command -q fzf; and fzf --fish | source
command -q mise; and mise activate fish | source
command -q direnv; and direnv hook fish | source
command -q secrets; and secrets activate fish | source
command -q atuin; and atuin init fish --disable-up-arrow | source
command -q zoxide; and zoxide init fish | source
command -q orb; and source ~/.orbstack/shell/init2.fish 2>/dev/null
if test -d "/Users/shardul/Library/pnpm"
    set -gx PNPM_HOME "/Users/shardul/Library/pnpm"
    if not string match -q -- $PNPM_HOME $PATH
        set -gx PATH "$PNPM_HOME" $PATH
    end
end


if status is-interactive
    set fish_greeting

    alias vi='nvim'
    alias vim='nvim'
    alias rm='trash'
    alias rmfrfr='rm'
    alias cm=chezmoi

    function select_changeset
        set -l changesets (jj log -r 'all()' --no-graph --no-pager --color=always -T 'builtin_log_oneline' -n100 | fzf --reverse --ansi --accept-nth=1 --prompt="Select changeset: ")
        if test -z "$changesets"
            echo "Cancelled: No changeset selected" 1>&2
            return 1
        end
        echo $changesets
    end

    # Generate PR description using Claude
    function genpr
        # Select head changeset (current branch)
        set -l head (select_changeset)
        if test $status -ne 0
            return 1
        end

        set -l base (select_changeset)
        if test $status -ne 0
            return 1
        end

        claude -p "/genpr $base_id $head_id"
    end

    function claude
        if set -q SSH_CLIENT; or set -q SSH_TTY
            if not set -q _SSH_DID_UNLOCK
                echo "🔐 Unlocking keychain for Claude in SSH session..."
                security unlock-keychain ~/Library/Keychains/login.keychain-db
                set -gx _SSH_DID_UNLOCK 1
            end
        end
        /Users/shardul/.claude/local/claude --dangerously-skip-permissions $argv
    end

    # ─────────────────────────────────────────────────────────────────────────
    # Prompt
    # ─────────────────────────────────────────────────────────────────────────
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
        echo (basename (pwd))
    end

    set -gx MANPAGER "sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"
end
