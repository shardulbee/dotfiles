{
  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew = {
      url= "github:zhaofengli-wip/nix-homebrew";
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    aerospace = {
      url = "github:nikitabobko/homebrew-tap";
      flake = false;
    };
  };

  outputs = inputs@{ self
    , nix-darwin
    , nixpkgs
    , nixpkgs-unstable
    , nix-homebrew
    , homebrew-core
    , homebrew-cask
    , homebrew-bundle
    , aerospace
  }: let
    # Helper function to create a package set with unstable Neovim
    mkPkgs = system: import nixpkgs {
      inherit system;
      nixpkgs.config.allowUnfree = true;
      overlays = [
        (final: prev: {
          neovim = nixpkgs-unstable.legacyPackages.${system}.neovim;
        })
      ];
    };
  in {
    nixosConfigurations."vm-aarch64" = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./machines/nixos.nix
      ];
      specialArgs = {
        pkgs = mkPkgs "aarch64-linux";
      };
    };

    darwinConfigurations."turbochardo" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin"; # Assuming Apple Silicon
      modules = [
        nix-homebrew.darwinModules.nix-homebrew {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = "shardul";
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
              "homebrew/homebrew-bundle" = homebrew-bundle;
              "nikitabobko/homebrew-tap" = aerospace;
            };
            mutableTaps = false;
          };
        }
        ./machines/darwin.nix
      ];
      specialArgs = {
        inherit inputs;
        pkgs = mkPkgs "aarch64-darwin";
      };
    };
  };
}
