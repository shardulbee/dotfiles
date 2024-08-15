bindkey -e

# -----------------------------------------------------------------------------
# Prompt
# -----------------------------------------------------------------------------
setopt prompt_subst
setopt TRANSIENT_RPROMPT
precmd () {print -Pn "\e]0;%2d\a"}

PROMPT="%B%F{64}%1d%b %F{220}$%f "
git_status() {
  if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    return
  fi

  local DIRTY="%F{64}clean" BRANCH
  [[ -n $(git diff-files --quiet || echo "dirty") ]] && DIRTY="%B%F{red}dirty"

  BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
  echo "%F{blue}on branch %B%F{64}${BRANCH} %b%F{blue}working status ${DIRTY}"
}
RPROMPT='$(git_status)'

# -----------------------------------------------------------------------------
# Completion
# -----------------------------------------------------------------------------
autoload -Uz compinit
for dump in $ZDOTDIR/.zcompdump(N.mh+24); do
  compinit
done
compinit -C

# -----------------------------------------------------------------------------
# History
# -----------------------------------------------------------------------------
HISTSIZE="100000000"
SAVEHIST="100000000"
HISTFILE="$HOME/.zsh_history"
setopt HIST_FCNTL_LOCK
setopt HIST_IGNORE_DUPS
unsetopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
unsetopt HIST_EXPIRE_DUPS_FIRST
setopt SHARE_HISTORY
unsetopt EXTENDED_HISTORY
setopt autocd

# -----------------------------------------------------------------------------
# Sources
# -----------------------------------------------------------------------------
# if command -v /usr/local/bin/direnv > /dev/null; then
#   eval "$(/usr/local/bin/direnv hook zsh)"
# else
#   echo "direnv not found"
#   return 1
# fi
# -----------------------------------------------------------------------------
# Aliases
# -----------------------------------------------------------------------------
alias vi=nvim
alias vim=nvim
alias be='bundle exec'
alias blush='git commit --amend --reuse-message HEAD'
alias crepo='create-repo'
alias ga='git add -A'
alias gb='git for-each-ref --sort=-committerdate refs/heads/ --format='\''%(color:red)%(committerdate:short) %(color:yellow)%(objectname:short) %(color:white)%(refname:short)'\'''
alias gbrc='gco master && gfogro && git branch --merged | grep -v '\''master'\'' | xargs git branch -d'
alias gc='git commit --verbose'
alias gcb='git rev-parse --abbrev-ref HEAD'
alias gco='git checkout'
alias gcob='git checkout -b'
alias gcom='git checkout master'
alias gcp='git cherry-pick'
alias gd='git diff'
alias gdom='git diff origin/master'
alias gfo='git fetch origin master'
alias gfogro='gfo && gro'
alias gfork='git merge-base --fork-point origin/master @'
alias gl='git log --pretty=format:'\''%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'\'' --abbrev-commit --date=local'
alias gra='git rebase --abort'
alias grc='git rebase --continue'
alias gro='git rebase origin/master'
alias gs='git status --short --branch'
alias gupd='gfogro; gpf'
alias vrepo='gh repo view --web > /dev/null'
alias cat='bat --style=plain,numbers,grid'
alias rm="trash"
alias rmfrfr="rm" # aka rm for real for real

function gbr { git checkout $(git branch | sed 's/[\* ]//g' | fzf --height 30) }
function gdo { git diff origin $(gcb) }
function grim { git rebase --interactive $(gfork) }
function gpf {
  if [[ $(gcb) != "master"  ]]; then
    git push --force-with-lease
  else
    echo "Nope"
  fi;
}

# https://github.com/zdharma-continuum/fast-syntax-highlighting/issues/27#issuecomment-1267278072
function whatis() { if [[ -v THEFD ]]; then :; else command whatis "$@"; fi; }
