# vim: set ft=zsh

export XDG_CONFIG_HOME=$HOME/.config
export ZDOTDIR=$XDG_CONFIG_HOME/zsh
export RIPGREP_CONFIG_PATH=$XDG_CONFIG_HOME/ripgrep/ripgreprc
export CLICOLOR=1
export EDITOR=nvim
export PATH=$PATH:$HOME/bin:/opt/homebrew/bin
export NOTES_DIR="$HOME/gdrive/Notes"
export MANPAGER="col -bx | bat -l man -p"
export LC_ALL="en_US.UTF-8"
export COLORTERM='truecolor'
export FZF_DEFAULT_CMD="fd -tf --hidden"
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_CMD
