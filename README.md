# dotfiles

Nix is the control plane for the `sharchy` NixOS workstation and the `macbook`
macOS host. Home Manager owns the shared user environment; nix-darwin owns
macOS settings and the Homebrew GUI-app escape hatch.

Small glue configuration is inlined where it is used. Application configuration
that is useful to edit directly remains under `config/`.

## macOS

Install Determinate Nix and Homebrew, clone this repository to
`~/Documents/dotfiles`, then run:

```sh
sudo nix run nix-darwin -- switch --flake .#macbook
```

Subsequent updates are simply:

```sh
rebuild
```

Homebrew cleanup is set to `uninstall`: undeclared formulae and casks, including
the retired `omp`, are removed during activation. Application data is not
zapped.

## NixOS

```sh
nix flake check
sudo nixos-rebuild switch --flake .#sharchy
```

Subsequent updates can also use `rebuild`.

## Package ownership

- Nix provides command-line tools, including Pi from nixpkgs unstable.
- `packages/playwriter.nix` pins and builds Playwriter from its npm lockfile.
- nix-darwin declares proprietary macOS applications as Homebrew casks.
- Secrets and application state remain outside the Nix store.
