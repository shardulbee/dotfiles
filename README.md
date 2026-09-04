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

Orb setup installs the Attic client. When the dotfiles Amp project provides the
`ATTIC_TOKEN` secret, the resume hook configures the private `turbochardo` cache
on Sharbox over Tailscale. A supervised store watcher uploads newly built paths
for reuse by fresh orbs, so normal Nix commands use the cache without
Cloudflare's request-size limit:

```sh
nix flake check path:.
nix build path:.#nixosConfigurations.sharchy.config.system.build.toplevel
```

Without the token, Nix uses its default substituters and no paths are uploaded.
