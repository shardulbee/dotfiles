# vim: ts=2 sw=2 et

/opt/homebrew/bin/brew shellenv | source
fish_add_path -P $HOME/bin

direnv hook fish | source

zoxide init fish | source
fzf --fish | source

if test -z $ASDF_DATA_DIR
    set _asdf_shims "$HOME/.asdf/shims"
else
    set _asdf_shims "$ASDF_DATA_DIR/shims"
end
if not contains $_asdf_shims $PATH
    set -gx --prepend PATH $_asdf_shims
end
set --erase _asdf_shims


set -gx EDITOR 'nvim'
set -gx MANPAGER "col -bx | bat -l man -p"
set -gx FZF_DEFAULT_CMD "fd -tf --hidden"
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_CMD"

function file-list-tags
    rg --hidden --sort path --files \
        --glob '!target' \
        --glob '!vendor' \
        --type-not html \
        --type-not css \
        --type-not xml \
        --type-not markdown \
        --type-not jsonl \
        --type-not yaml \
        --type-not json \
        --type-not diff \
        --type-not asciidoc \
        --type-not avro \
        --type-not haml \
        --type-not license \
        --type-not log \
        --type-not mk \
        --type-not pdf \
        --type-not protobuf \
        --type-not readme \
        --type-not tex \
        --type-not thrift \
        --type-not toml \
        --type-not js \
    > .file_list_tags
end

function ctags-build
    file-list-tags
    /opt/homebrew/bin/ctags -f tags -L .file_list_tags --sort=yes \
        --quiet=yes
end

function gbr
   git checkout (git branch | sed 's/[\* ]//g' | fzf --height 30 --ansi --tmux --preview="git show {}")
end

function gpf
    if test (git rev-parse --abbrev-ref HEAD) != "main"
        git push --force-with-lease
    else
        echo "Nope"
    end
end

if test (hostname) != "turbochardo"
    set -gx SECRETS_FILE "$HOME/Documents/secrets.age"
    set -gx SECRETS_HOSTS "$HOME/Documents/secrets.hosts"
end

secrets activate | source


if status is-interactive
set fish_greeting

alias ls=eza
alias lsfr=ls
alias vi='nvim'
alias vim='nvim'
alias cat='bat --style=plain,numbers,grid'
alias rm='trash'
alias rmfrfr='rm'
alias z=zi
alias gc="git commit"
alias gp="git push"
alias gfo="git fetch origin"
alias gro="git rebase origin/main || git rebase origin/master"
alias gfogro="gfo; and gro"
alias blush="git commit --amend --no-edit"
alias gs="git status"
alias gl="git log"
alias gco="git checkout"
alias gcob="git checkout -b"
alias gd="git diff"
alias gdom="git diff origin/main"
alias ga='git add -A'
alias gb='git for-each-ref --sort=-committerdate refs/heads/ --format='\''%(color:red)%(committerdate:short) %(color:yellow)%(objectname:short) %(color:white)%(refname:short)'\'''
alias gc='git commit --verbose'
alias gcb='git rev-parse --abbrev-ref HEAD'

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

function fish_title
    echo (basename (pwd))
end

end
