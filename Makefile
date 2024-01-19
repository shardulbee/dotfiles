UNAME := $(shell uname)
NIXNAME := $(shell hostname)
DESIRED_HOSTNAME := turbochardo

switch:
ifeq ($(NIXNAME), $(DESIRED_HOSTNAME))
	nix build --extra-experimental-features nix-command --extra-experimental-features flakes ".#darwinConfigurations.${NIXNAME}.system"
	./result/sw/bin/darwin-rebuild switch --flake "$$(pwd)#${NIXNAME}"
else
	sudo scutil --set ComputerName $(DESIRED_HOSTNAME)
	sudo scutil --set HostName $(DESIRED_HOSTNAME)
	sudo scutil --set LocalHostName $(DESIRED_HOSTNAME)
	nix build --extra-experimental-features nix-command --extra-experimental-features flakes ".#darwinConfigurations.${DESIRED_HOSTNAME}.system"
	./result/sw/bin/darwin-rebuild switch --flake "$$(pwd)#${DESIRED_HOSTNAME}"
endif
