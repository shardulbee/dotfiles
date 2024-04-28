# vim: set ft=zsh fdm=marker fdl=0:vim
# zmodload zsh/zprof
# zmodload zsh/datetime
# setopt PROMPT_SUBST
# PS4='+$EPOCHREALTIME %N:%i> '
# logfile=$(mktemp zsh_profile.XXXXXXXX)
# echo "Logging to $logfile"
# exec 3>&2 2>$logfile
# setopt XTRACE

bindkey -e

# {{{ prompt
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
# }}}

# {{{ compinit
autoload -Uz compinit
for dump in $ZDOTDIR/.zcompdump(N.mh+24); do
  compinit
done
compinit -C
# }}}

# {{{ history
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
# }}}

# {{{ sources
opam() {
  if command -v /opt/homebrew/bin/opam > /dev/null; then
    eval "$(/opt/homebrew/bin/opam env)"
    /opt/homebrew/bin/opam "$@"
  else
    echo "opam not found"
    return 1
  fi
}
if command -v /usr/local/bin/direnv > /dev/null; then
  eval "$(/usr/local/bin/direnv hook zsh)"
else
  echo "direnv not found"
  return 1
fi

# direnv() {
#   if command -v /usr/local/bin/direnv > /dev/null; then
#     eval "$(/usr/local/bin/direnv hook zsh)"
#     /usr/local/bin/direnv "$@"
#   else
#     echo "direnv not found"
#     return 1
#   fi
# }
# }}}

# {{{ custom functions
function gbd {
  local branch=$(git branch | sed 's/[\* ]//g' | fzf --multi --height 30)
  if [ -n "$branch" ]; then
    echo $branch | while IFS= read -r line; do
      git branch -D $line
    done
  fi
}

function gbr {
  git checkout $(git branch | sed 's/[\* ]//g' | fzf --height 30)
}

function gp {
  if [[ -z $(git for-each-ref --format='%(upstream:short)' $(git symbolic-ref -q HEAD))  ]]; then
    git push -u
  else
    git push
  fi
}

function gdo { git diff origin $(gcb) }
function grim { git rebase --interactive $(gfork) }

function gpf {
  if [[ $(gcb) != "master"  ]]; then
    git push --force-with-lease
  else
    echo "Nope"
  fi;
}

fzf-redraw-prompt() {
  local precmd
  for precmd in $precmd_functions; do
    $precmd
  done
  zle reset-prompt
}
zle -N fzf-redraw-prompt

# Command that allows quickly switching to different GitHub repos using CTRL-F
function fzf-repo-widget {
  local dirs=$(fd -td --exact-depth 3 . $HOME/src)
  local dirs="$dirs\n/Users/shardul/dotfiles"
  local dir=$(echo "$dirs" | FZF_DEFAULT_OPTS="--height 40% --reverse --prompt='Git repos> ' $FZF_DEFAULT_OPTS" fzf)

  if [[ -z "$dir" ]]; then
    zle redisplay
    return 0
  fi

  cd $dir
  fzf-redraw-prompt
}
zle -N fzf-repo-widget
bindkey ^F fzf-repo-widget

function create-repo {
  local repo_name=$1

  if [[ -z "$repo_name" ]]; then
    echo "Usage: create-repo <repo-name>"
    return 1
  fi

  local repo_path="$HOME/src/github.com/shardulbee/$repo_name"

  # Create local git repository
  mkdir -p "$repo_path"
  cd "$repo_path"
  git init

  # Create public GitHub repository using gh tool
  gh repo create "$repo_name" --private --remote=origin --source=.
}

function cheat() { curl cheat.sh/"$1" }

# https://github.com/zdharma-continuum/fast-syntax-highlighting/issues/27#issuecomment-1267278072
function whatis() { if [[ -v THEFD ]]; then :; else command whatis "$@"; fi; }
# }}}

# {{{ aliases
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
# }}}

export FZF_DEFAULT_CMD="fd -tf --hidden"
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_CMD

# unsetopt XTRACE
# exec 2>&3 3>&-
# zprof
