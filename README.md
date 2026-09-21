# dotfiles

Portable shell and editor configuration as a Home Manager module.

```nix
inputs.dotfiles.url = "github:shardulbee/dotfiles";

home-manager.users.alice.imports = [ inputs.dotfiles.homeModules.default ];
```

Consumers provide identity, home directory, state version, packages, and machine configuration.
