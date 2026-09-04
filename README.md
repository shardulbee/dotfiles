# dotfiles

Nix configuration for the `sharchy` NixOS workstation and `macbook` macOS host.

Expected checkout: `~/Documents/dotfiles`.

## Apply

```sh
# First macOS activation
sudo nix run nix-darwin -- switch --flake .#macbook

# NixOS
nix flake check
sudo nixos-rebuild switch --flake .#sharchy

# Later changes on either host
rebuild
```

## Deploy Sharchy from an Amp orb

The orb must have `TAILSCALE_CLIENT_ID` and `TAILSCALE_AUDIENCE` set for
the dotfiles project's Tailscale workload identity. Its
`SHARCHY_DEPLOY_SSH_KEY` secret authenticates standard OpenSSH after Tailscale
admits the short-lived deploy node. Push `main`, then deploy that exact commit:

```sh
git push origin HEAD
nix run .#deploy-sharchy
```

The deployment joins Tailscale as a short-lived `tag:amp-dotfiles-deploy`
node, connects to Sharchy as `shardul` over standard OpenSSH, and rebuilds the
exact pushed commit. Local and orb-triggered Sharchy rebuilds share
`/run/lock/sharchy-deploy.lock`.
