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
fi

if [[ -n ${ZED_TERM:-} && -z ${SSH_CONNECTION:-} ]]; then
  export EDITOR='zed --wait'
else
  export EDITOR=nvim
fi

# Machine-specific settings.
[[ -r ${ZDOTDIR:-$HOME}/.zshrc.local ]] && source "${ZDOTDIR:-$HOME}/.zshrc.local"
