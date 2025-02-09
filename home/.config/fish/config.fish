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

    source /opt/homebrew/opt/asdf/libexec/asdf.fish

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

    function gpf
        if test (gcb) != "main"
            git push --force-with-lease
        else
            echo "Nope"
        end
    end

    function try -a program
        if not test -n "$program"
            echo "Error: Program name required" >&2
            return 1
        end
        nix run "nixpkgs#$program"
    end
end
