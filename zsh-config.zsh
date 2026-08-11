# Fish-like Zsh without a framework or plugin manager.

# PATH, highest priority first.
typeset -U path PATH
path=("$HOME/.local/share/mise/shims" "$HOME/.local/bin" "$HOME/bin" /opt/homebrew/bin $path)

# Do not keep a second, plaintext shell history. Atuin is the only history.
HISTFILE=/dev/null
HISTSIZE=0
SAVEHIST=0
unsetopt APPEND_HISTORY EXTENDED_HISTORY INC_APPEND_HISTORY SHARE_HISTORY

# Fish-like interactive defaults.
bindkey -e
setopt AUTO_CD INTERACTIVE_COMMENTS

# Match Fish's default prompt: user@host ~/a/basename>.
_fishy_prompt_pwd() {
  local path=${PWD/#$HOME/\~}
  local -a parts=("${(@s:/:)path}")
  local i suffix='>'
  for (( i = 1; i < $#parts; i++ )); do
    [[ -z ${parts[i]} || ${parts[i]} == '~' ]] || parts[i]=${parts[i][1]}
  done
  (( EUID == 0 )) && suffix='#'
  fishy_pwd="${(j:/:)parts}"
  PROMPT="%F{10}%n%f@%m %F{green}${fishy_pwd}%f${suffix} "
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _fishy_prompt_pwd
_fishy_prompt_pwd

# Native completion. Trust and compile the dump instead of rescanning every startup.
autoload -Uz compinit
zcompdump=${ZDOTDIR:-$HOME}/.zcompdump
compinit -C -d "$zcompdump"
if [[ -s $zcompdump && (! -s $zcompdump.zwc || $zcompdump -nt $zcompdump.zwc) ]]; then
  zcompile -R "$zcompdump.zwc" "$zcompdump"
fi
unset zcompdump
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Fish-like autosuggestions, with Atuin as the sole suggestion provider.
for plugin in /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
              /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
              /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh; do
  if [[ -r $plugin ]]; then
    source "$plugin"
    break
  fi
done
ZSH_AUTOSUGGEST_USE_ASYNC=1

if (( $+commands[atuin] )); then
  atuin_init=${XDG_CACHE_HOME:-$HOME/.cache}/atuin/init.zsh
  if [[ ! -r $atuin_init || $commands[atuin] -nt $atuin_init ]]; then
    mkdir -p "${atuin_init:h}"
    atuin init zsh --disable-up-arrow >| "$atuin_init"
  fi
  # Avoid spawning `atuin uuid` on every shell just to make a session ID.
  if [[ -z ${ATUIN_SESSION:-} || ${ATUIN_SHLVL:-} != $SHLVL ]]; then
    zmodload zsh/datetime
    printf -v ATUIN_SESSION '%08x-%04x-4%03x-8%03x-%012x' \
      $EPOCHSECONDS $(( $$ & 0xffff )) $(( RANDOM & 0xfff )) $(( RANDOM & 0xfff )) \
      $(( (EPOCHSECONDS & 0xffffffff) * 65536 + RANDOM ))
    export ATUIN_SESSION ATUIN_SHLVL=$SHLVL
  fi
  source "$atuin_init"
  ZSH_AUTOSUGGEST_STRATEGY=(atuin)
  unset atuin_init

  # Up/Down cycle through Atuin results inline; Ctrl-R keeps the full UI.
  _atuin_history_up() {
    if (( ! _atuin_history_index )) || [[ $BUFFER != $_atuin_history_selected ]]; then
      _atuin_history_query=$BUFFER
      _atuin_history_lines=("${(@0)$(atuin search --cmd-only --print0 --author '$all-user' --limit 100 --search-mode prefix -- "$BUFFER" 2>/dev/null)}")
      _atuin_history_lines=("${(@)_atuin_history_lines:#}")
      _atuin_history_lines=("${(@Oa)_atuin_history_lines}")
      (( $#_atuin_history_lines )) || return
      _atuin_history_index=1
    elif (( _atuin_history_index < $#_atuin_history_lines )); then
      (( _atuin_history_index++ ))
    fi
    BUFFER=${_atuin_history_lines[_atuin_history_index]}
    _atuin_history_selected=$BUFFER
    CURSOR=$#BUFFER
  }
  _atuin_history_down() {
    [[ $BUFFER == $_atuin_history_selected ]] || return
    if (( _atuin_history_index > 1 )); then
      (( _atuin_history_index-- ))
      BUFFER=${_atuin_history_lines[_atuin_history_index]}
    else
      _atuin_history_index=0
      BUFFER=$_atuin_history_query
    fi
    _atuin_history_selected=$BUFFER
    CURSOR=$#BUFFER
  }
  zle -N _atuin_history_up
  zle -N _atuin_history_down
  bindkey '^[[A' _atuin_history_up
  bindkey '^[OA' _atuin_history_up
  bindkey '^[[B' _atuin_history_down
  bindkey '^[OB' _atuin_history_down
fi

if (( $+commands[zoxide] )); then
  zoxide_init=${XDG_CACHE_HOME:-$HOME/.cache}/zoxide/init.zsh
  if [[ ! -r $zoxide_init || $commands[zoxide] -nt $zoxide_init ]]; then
    mkdir -p "${zoxide_init:h}"
    zoxide init zsh >| "$zoxide_init"
  fi
  source "$zoxide_init"
  unset zoxide_init
fi

if [[ -n ${ZED_TERM:-} && -z ${SSH_CONNECTION:-} ]]; then
  export EDITOR='zed --wait'
else
  export EDITOR=nvim
fi
alias vim=nvim
edit() {
  ${=EDITOR} "$@"
}
pir() {
  SHARPI_ATTACH_PI="$HOME/.local/share/mise/installs/npm-earendil-works-pi-coding-agent/0.82.1/bin/pi" \
    "$HOME/Documents/sharpi/scripts/attach" "$@"
}
try() {
  (( $# )) || { print -u2 'Usage: try <package> [package ...]'; return 1; }
  local -a packages
  local package
  for package; do
    packages+=("nixpkgs#$package")
  done
  nix run "$packages[@]"
}
y() {
  local tmp cwd
  tmp=$(mktemp -t 'yazi-cwd.XXXXXX') || return
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [[ -n $cwd && $cwd != $PWD && -d $cwd ]] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

# Machine-specific settings.
[[ -r ${ZDOTDIR:-$HOME}/.zshrc.local ]] && source "${ZDOTDIR:-$HOME}/.zshrc.local"
