{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew = {
      url= "github:zhaofengli-wip/nix-homebrew";
    };
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
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
	, nix-homebrew
	, homebrew-core
	, homebrew-cask
    , homebrew-bundle
    , aerospace
    , nixpkgs-unstable
      }: {
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
                    "nikitabobko/homebrew-tap" = aerospace;
           	    };
           	    mutableTaps = false;
            };
        }
    	./darwin.nix
      ];
      specialArgs = { inherit inputs; };
    };
  };
}
