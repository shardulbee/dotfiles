{
  description = "Shardul's Linux and macOS dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      nixosConfigurations.sharchy = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./nixos/hosts/sharchy/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.shardul = import ./nixos/home/shardul.nix;
          }
        ];
      };

      nixosConfigurations.sharchy-vm = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./nixos/hosts/sharchy-vm/configuration.nix
          home-manager.nixosModules.home-manager
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
