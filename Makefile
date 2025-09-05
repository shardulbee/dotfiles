OS := $(shell uname -s)
HOST := $(shell hostname -s)
CMD := $(if $(filter Darwin,$(OS)),darwin-rebuild,nixos-rebuild)

# Main target: rebuild Nix configuration
switch:
	sudo $(CMD) switch --flake .#$(HOST)

# Test configuration without switching
test:
	sudo $(CMD) test --flake .#$(HOST)

# Build configuration without switching
build:
	sudo $(CMD) build --flake .#$(HOST)

# Symlink dotfiles (can be called manually or by Nix activation)
symlink:
	@make -f Makefile.dotfiles install

# Bootstrap from scratch using GitHub flake
bootstrap:
	@echo "Bootstrapping from github:shardulbee/dotfiles..."
	sudo $(CMD) switch --flake github:shardulbee/dotfiles#$(HOST)

# Update flake inputs
update:
	nix flake update

# Show flake info
info:
	nix flake info
	nix flake metadata

# Clean up old generations
clean:
	sudo nix-collect-garbage -d

# Development: format nix files
fmt:
	nixfmt-classic modules/*.nix flake.nix

.PHONY: switch test build symlink bootstrap update info clean fmt