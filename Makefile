DESIRED_HOSTNAME := turbochardo
CURRENT_HOSTNAME := $(shell hostname)

switch:
	@if [ "$(CURRENT_HOSTNAME)" != "$(DESIRED_HOSTNAME)" ]; then \
		echo "Updating hostname to $(DESIRED_HOSTNAME)"; \
		sudo scutil --set ComputerName $(DESIRED_HOSTNAME); \
		sudo scutil --set HostName $(DESIRED_HOSTNAME); \
		sudo scutil --set LocalHostName $(DESIRED_HOSTNAME); \
	fi
	nix run nix-darwin -- switch --flake .#$(DESIRED_HOSTNAME)
