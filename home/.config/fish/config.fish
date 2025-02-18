if status is-interactive

set fish_greeting
fish_add_path $HOME/bin /opt/homebrew/bin
set -gx EDITOR 'nvim'
set -gx MANPAGER "col -bx | bat -l man -p"
set -gx FZF_DEFAULT_CMD "fd -tf --hidden"
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_CMD"

if command -sq direnv
    direnv hook fish | source
else
    echo "direnv not found"
end

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

alias vi='nvim'
alias vim='nvim'
alias blush='git commit --amend --no-edit'
alias ga='git add -A'
alias gb="git for-each-ref --sort=-committerdate refs/heads/ --format='%(color:red)%(committerdate:short) %(color:yellow)%(objectname:short) %(color:white)%(refname:short)'"
alias gfo='git fetch origin main'
alias gd='git diff'
alias gfogro='gfo && gro'
alias gl='git log --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit --date=local'
alias gro='git rebase origin/main'
alias gs='git status --short --branch'
alias cat='bat --style=plain,numbers,grid'
alias rm='trash'
alias gp='git p'
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

    set_color normal
    echo -n ' → '
end

end
