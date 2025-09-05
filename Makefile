switch:
	sudo darwin-rebuild switch --flake .#$$(hostname -s)

.PHONY: switch
