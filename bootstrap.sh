#!/bin/bash

EXPECTED_HOSTNAME="turbochardo"
CURRENT_COMPUTER_NAME=$(scutil --get ComputerName)
CURRENT_LOCAL_HOSTNAME=$(scutil --get LocalHostName)
CURRENT_HOSTNAME=$(scutil --get HostName)

# Set ComputerName, LocalHostName and HostName if they aren't what you expect
if [ "$EXPECTED_HOSTNAME" != "$CURRENT_COMPUTER_NAME" ] ; then
    sudo scutil --set ComputerName $EXPECTED_HOSTNAME
fi

if [ "$EXPECTED_HOSTNAME" != "$CURRENT_LOCAL_HOSTNAME" ] ; then
    sudo scutil --set LocalHostName $EXPECTED_HOSTNAME
fi

if [ "$EXPECTED_HOSTNAME" != "$CURRENT_HOSTNAME" ] ; then
    sudo scutil --set HostName $EXPECTED_HOSTNAME
fi

# Install Nix if not already installed
if ! command -v nix &> /dev/null ; then
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
fi

nix build --extra-experimental-features nix-command --extra-experimental-features flakes ".#darwinConfigurations.${EXPECTED_HOSTNAME}.system"
./result/sw/bin/darwin-rebuild switch --flake "$(pwd)#${EXPECTED_HOSTNAME}"
