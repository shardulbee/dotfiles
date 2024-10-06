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
  };

  outputs = inputs@{ self
	, nix-darwin
	, nixpkgs
	, nixpkgs-unstable
	, nix-homebrew
	, homebrew-core
	, homebrew-cask
	, homebrew-bundle
      }: let
    in {
    nixosConfigurations."vm-aarch64" = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./nixos.nix
      ];
    };
    darwinConfigurations."turbochardo" = nix-darwin.lib.darwinSystem {
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
	    };
	    mutableTaps = false;
          };
        }
	./darwin.nix
      ];
      specialArgs = { inherit inputs; };
    };

    darwinPackages = self.darwinConfigurations."turbochardo".pkgs;
  };
}
