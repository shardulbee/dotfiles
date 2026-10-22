# dotfiles

Portable dotfiles exported as a Home Manager module.

## Deployment

Hosts use the Dotfiles revision committed in `shardulbee/homelab/flake.lock`,
never whichever revision happens to be on Dotfiles `main` at deploy time.
After pushing a Dotfiles change, explicitly promote it in Homelab:

```sh
nix flake update dotfiles
# Review the revision and changes, then commit flake.lock and push main.
```

Verify Homelab's deployment on every online host. Sleeping workstations remain
pending until they next deploy. There is no Dotfiles push-triggered deploy.

```nix
inputs.dotfiles.url = "github:shardulbee/dotfiles";

home-manager.users.alice.imports = [ inputs.dotfiles.homeModules.default ];
```
