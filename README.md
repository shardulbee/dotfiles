# dotfiles

Portable dotfiles exported as a Home Manager module.

```nix
inputs.dotfiles.url = "github:shardulbee/dotfiles";

home-manager.users.alice.imports = [ inputs.dotfiles.homeModules.default ];
```
