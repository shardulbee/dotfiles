fish_add_path -aP /opt/homebrew/bin # append homebrew
fish_add_path -p $HOME/bin

if command -sq /opt/homebrew/bin/direnv
    /opt/homebrew/bin/direnv hook fish | source
else
    echo "direnv not found"
end

set -gx EDITOR 'nvim'
set -gx MANPAGER "col -bx | bat -l man -p"
set -gx FZF_DEFAULT_CMD "fd -tf --hidden"
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_CMD"

if status is-interactive


set fish_greeting

if command -sq zoxide
    zoxide init fish | source
else
    echo "zoxide not found"
end

if command -sq fzf
    fzf --fish | source
else
    echo "fzf not found"
end

alias vim='nvim'
alias cat='bat --style=plain,numbers,grid'
alias rm='trash'
alias rmfrfr='rm'
alias z=zi
alias gc="git commit"

function gpf
    if test (git rev-parse --abrev-ref HEAD) != "main"
        git push --force-with-lease
    else
        echo "Nope"
    end
end

# Fish prompt customization
function fish_prompt
    set -l last_status $status

    # Show success/error indicator with status code
    if test $last_status -eq 0
        set_color green
        echo -n "✓ "
    else
        set_color red
        echo -n "✘ $last_status "
    end

    # Current directory - warm bright green
    set_color 55a630  # Spring green
    echo -n (basename (pwd))
    set_color normal

    # Git status
    if command -sq git; and git rev-parse --is-inside-work-tree >/dev/null 2>&1
        # Branch name in yellow
        set_color yellow
        printf ' (%s)' (git branch --show-current)

        # Status indicator - red if dirty, green if clean
        if not git diff --quiet HEAD --
            set_color red
            echo -n ' ●'
        else
            set_color green
            echo -n ' ●'
        end
    end

    # Show backgrounded jobs
    set -l jobs_count (jobs | count)
    if test $jobs_count -gt 0
        set_color blue
        set -l pname (jobs -c | head -n1)
        echo -n " [background:$pname]"
    end

    set_color normal
    echo -n ' → '
end

end
