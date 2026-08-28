{
  description = "Shardul's Linux and macOS dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    clipway = {
      url = "github:krisztianfekete/clipway";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helium = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, clipway, helium, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      nixosConfigurations.sharchy = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./nixos/hosts/sharchy/configuration.nix
          home-manager.nixosModules.home-manager
          helium.nixosModules.default
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-backup";
            home-manager.users.shardul = import ./nixos/home/shardul.nix;
          }
        ];
      };

      nixosConfigurations.sharchy-vm = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./nixos/hosts/sharchy-vm/configuration.nix
          home-manager.nixosModules.home-manager
          clipway.nixosModules.default
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.shardul = import ./nixos/home/shardul-vm.nix;
          }
        ];
      };

      homeConfigurations."shardul@sharchy" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./nixos/home/shardul.nix ];
      };
    };
}
