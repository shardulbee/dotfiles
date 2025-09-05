{
  description = "Shardul's macOS Configuration with Dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    jjui.url = "github:idursun/jjui";
    jjui.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nix-darwin,
      home-manager,
      nix-homebrew,
      jjui,
      nixpkgs,
      ...
    }:
    let
      # Build the secrets package
      secretsPkg = pkgs: pkgs.callPackage ./secrets { };

      # Make jjui and secrets available to all modules
      specialArgs = {
        inherit jjui;
        inherit secretsPkg;
      };
    in
    {
      darwinConfigurations."turbochardo" = nix-darwin.lib.darwinSystem {
        inherit specialArgs;
        modules = [
          ./modules/darwin.nix
          ({ pkgs, ... }: {
            networking.computerName = "turbochardo";
            networking.hostName = "turbochardo";
            
            # Add jjui and secrets to system packages
            environment.systemPackages = with pkgs; [
              jjui.packages.${pkgs.system}.default
              (secretsPkg pkgs)
            ];

            # Set Git commit hash for darwin-version
            system.configurationRevision = self.rev or self.dirtyRev or null;
          })
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = "shardul";
              autoMigrate = true;
            };
          }
          home-manager.darwinModules.home-manager
          {
            home-manager.backupFileExtension = "backup";
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.shardul = import ./modules/home.nix;
          }
        ];
      };

      darwinConfigurations."baricbook" = nix-darwin.lib.darwinSystem {
        inherit specialArgs;
        modules = [
          ./modules/darwin.nix
          ({ pkgs, ... }: {
            networking.computerName = "baricbook";
            networking.hostName = "baricbook";
            
            # Add jjui and secrets to system packages
            environment.systemPackages = with pkgs; [
              jjui.packages.${pkgs.system}.default
              (secretsPkg pkgs)
            ];

            # Set Git commit hash for darwin-version
            system.configurationRevision = self.rev or self.dirtyRev or null;
          })
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = "shardul";
              autoMigrate = true;
            };
          }
          home-manager.darwinModules.home-manager
          {
            home-manager.backupFileExtension = "backup";
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.shardul = import ./modules/home.nix;
          }
        ];
      };

      # NixOS configuration for LXC container
      nixosConfigurations.proxmox-lxc = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        inherit specialArgs;
        modules = [
          ./modules/nixos.nix
          ({ pkgs, ... }: {
            # Add jjui to system packages
            environment.systemPackages = with pkgs; [
              jjui.packages.${pkgs.system}.default
            ];
          })
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.shardul = import ./modules/home.nix;
          }
        ];
      };
    };
}