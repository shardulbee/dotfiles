D := $(shell pwd)
H := $(HOME)
OS := $(shell uname -s)

install:
	@mkdir -p $(H)/.claude/commands $(H)/.config/{atuin,fish/functions,git,jj,jjui/themes,mise,nvim,tmux} $(H)/.ssh $(H)/bin
	@ln -sfn $(D)/.claude/CLAUDE.md $(H)/.claude/CLAUDE.md
	@for file in $(D)/.claude/commands/*; do ln -sfn "$$file" "$(H)/.claude/commands/$$(basename "$$file")"; done
	@ln -sfn $(D)/.config/atuin/config.toml $(H)/.config/atuin/config.toml
	@ln -sfn $(D)/.config/fish/config.fish $(H)/.config/fish/config.fish
	@ln -sfn $(D)/.config/fish/functions/create-repo.fish $(H)/.config/fish/functions/create-repo.fish
	@for file in $(D)/.config/git/*; do ln -sfn "$$file" "$(H)/.config/git/$$(basename "$$file")"; done
	@ln -sfn $(D)/.config/jj/config.toml $(H)/.config/jj/config.toml
	@ln -sfn $(D)/.config/jjui/config.toml $(H)/.config/jjui/config.toml
	@ln -sfn $(D)/.config/jjui/themes/gruvbox-dark-hard.toml $(H)/.config/jjui/themes/gruvbox-dark-hard.toml
	@ln -sfn $(D)/.config/mise/config.toml $(H)/.config/mise/config.toml
	@for file in $(D)/.config/nvim/*; do ln -sfn "$$file" "$(H)/.config/nvim/$$(basename "$$file")"; done
	@ln -sfn $(D)/.config/tmux/tmux.conf $(H)/.config/tmux/tmux.conf
	@ln -sfn $(D)/.hushlogin $(H)/.hushlogin
	@ln -sfn $(D)/.ssh/config $(H)/.ssh/config
	@ln -sfn $(D)/.stylua.toml $(H)/.stylua.toml
	@ln -sfn $(D)/bin/telegram-notify $(H)/bin/telegram-notify
ifeq ($(OS),Darwin)
	@mkdir -p $(H)/.config/{aerospace,amp,ghostty,zed} $(H)/.hammerspoon $(H)/.zed $(H)/Library/Application\ Support/Cursor/User
	@rm -rf $(H)/Library/Application\ Support/espanso
	@ln -sfn $(D)/.config/espanso $(H)/Library/Application\ Support/espanso
	@ln -sfn $(D)/.config/aerospace/aerospace.toml $(H)/.config/aerospace/aerospace.toml
	@ln -sfn $(D)/.config/amp/settings.json $(H)/.config/amp/settings.json
	@ln -sfn $(D)/.config/ghostty/config $(H)/.config/ghostty/config
	@ln -sfn $(D)/.config/karabiner $(H)/.config/karabiner
	@for file in $(D)/.config/zed/*; do ln -sfn "$$file" "$(H)/.config/zed/$$(basename "$$file")"; done
	@ln -sfn $(D)/.hammerspoon/init.lua $(H)/.hammerspoon/init.lua
	@ln -sfn $(D)/.zed/settings.json $(H)/.zed/settings.json
	@for file in "$(D)/Library/Application Support/Cursor/User"/*; do ln -sfn "$$file" "$(H)/Library/Application Support/Cursor/User/$$(basename "$$file")"; done
	@ln -sfn $(D)/bin/golink.rb $(H)/bin/golink.rb
endif

.PHONY: install
