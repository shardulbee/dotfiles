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

      mkDarwinConfiguration =
        hostname:
        { pkgs, ... }:
        {
          nixpkgs.config.allowUnfree = true;

          # List packages installed in system profile
          environment.systemPackages = with pkgs; [
            # CLI tools
            bat
            fd
            fzf
            gh
            git
            delta
            jq
            neovim
            nodejs
            bun
            ripgrep
            stow
            universal-ctags
            zoxide
            btop
            direnv
            mise
            age
            python311Packages.uv
            uv
            jujutsu
            jjui.packages.${pkgs.system}.default
            difftastic
            lowdown
            darwin.trash
            hyperfine
            zig
            wget
            switchaudio-osx
            blueutil
            _1password-cli
            google-cloud-sdk
            bottom
            nixfmt-classic
            tmux
            pam-reattach
            reattach-to-user-namespace
            mosh
            atuin
            yazi
            (secretsPkg pkgs)
            nil
            nixd
            sourcekit-lsp

            # macOS GUI apps
            aerospace
            whatsapp-for-mac
            istat-menus
            bartender
            vscode
          ];

          # Homebrew packages that aren't available in nixpkgs
          homebrew = {
            enable = true;
            brews = [
              "libyaml"
              "openssl"
              "mas"
            ];
            casks = [
              "google-chrome"
              "1password"
              "hammerspoon"
              "raycast"
              "spotify"
              "zoom"
              "anki"
              "cursor"
              "homerow"
              "cleanshot"
              "google-drive"
              "vlc"
              "zwift"
              "dash"
              "slack"
              "zed"
              "ghostty"
              "discord"
              "obsidian"
              "orbstack"
              "activitywatch"
              "karabiner-elements"
              "espanso"
              "macwhisper"
              "claude"
              "antinote"
            ];
            masApps = {
              "Things 3" = 904280696;
            };
            onActivation.cleanup = "zap";
            onActivation.autoUpdate = false;
            onActivation.upgrade = false;
          };

          # Set the hostname based on configuration
          networking.computerName = hostname;
          networking.hostName = hostname;

          # macOS system configuration
          system.defaults = {
            # Dock settings
            dock.autohide = true;
            dock.mru-spaces = false;
            dock.minimize-to-application = true;
            dock.mineffect = "scale";
            dock.launchanim = false;
            dock.expose-animation-duration = 0.0;
            dock.orientation = "bottom";
            dock.show-recents = false;
            dock.static-only = true;

            # Finder settings
            finder.CreateDesktop = false;
            finder.FXPreferredViewStyle = "Nlsv";
            finder.ShowPathbar = true;

            # Global system preferences
            NSGlobalDomain.InitialKeyRepeat = 15;
            NSGlobalDomain.KeyRepeat = 1;
            NSGlobalDomain.ApplePressAndHoldEnabled = false;
            NSGlobalDomain.AppleKeyboardUIMode = 3;
            NSGlobalDomain."com.apple.keyboard.fnState" = false;
            NSGlobalDomain."com.apple.mouse.tapBehavior" = 1;
            NSGlobalDomain."com.apple.trackpad.trackpadCornerClickBehavior" = 1;
            NSGlobalDomain.NSAutomaticCapitalizationEnabled = false;
            NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false;
            NSGlobalDomain.NSAutomaticQuoteSubstitutionEnabled = false;
            NSGlobalDomain.NSAutomaticDashSubstitutionEnabled = false;
            NSGlobalDomain.NSAutomaticPeriodSubstitutionEnabled = false;
            NSGlobalDomain.NSAutomaticInlinePredictionEnabled = false;
            NSGlobalDomain.NSDocumentSaveNewDocumentsToCloud = false;
            NSGlobalDomain.NSNavPanelExpandedStateForSaveMode = true;
            NSGlobalDomain.AppleInterfaceStyle = "Dark";

            # Menu bar settings
            menuExtraClock.Show24Hour = true;
          };

          # Custom user preferences
          system.defaults.CustomUserPreferences = {
            "com.apple.symbolichotkeys" = {
              AppleSymbolicHotKeys = {
                # Disable 'Cmd + Space' for Spotlight Search (to use with Raycast)
                "64" = {
                  enabled = false;
                };
                # Disable 'Cmd + Alt + Space' for Finder search window
                "65" = {
                  enabled = false;
                };
              };
            };
          };

          # Primary user configuration
          system.primaryUser = "shardul";

          # Auto upgrade nix package and the daemon service
          nix.package = pkgs.nix;

          # managed by determinate
          nix.enable = false;

          # Necessary for using flakes on this system
          nix.extraOptions = ''
            experimental-features = nix-command flakes
            trusted-users = root @admin shardul
          '';

          # Enable fish shell
          programs.fish = {
            enable = true;
            useBabelfish = true;
          };

          # Enable Touch ID for sudo authentication
          security.pam.services.sudo_local = {
            touchIdAuth = true;
            reattach = true;
          };

          networking.knownNetworkServices = [
            "AX88179A"
            "Thunderbolt Bridge"
            "Wi-Fi"
            "Tailscale"
          ];

          services.tailscale = {
            enable = true;
            overrideLocalDns = true;
          };

          # Post-activation script to create symlinks and run dotfile installation
          system.activationScripts.postActivation.text = ''
            # Create symlinks to make Nix binaries available in standard locations
            [ -L /usr/local/bin/bin ] && rm /usr/local/bin/bin
            [ -L /usr/local/lib/lib ] && rm /usr/local/lib/lib

            for f in /run/current-system/sw/bin/*; do
              if [ -e "$f" ]; then
                ln -sfn "$f" /usr/local/bin/
              fi
            done

            for f in /run/current-system/sw/lib/*; do
              if [ -e "$f" ]; then
                ln -sfn "$f" /usr/local/lib/
              fi
            done

            # Clone or update dotfiles repository if needed
            DOTFILES_DIR="/Users/shardul/Documents/dotfiles"
            if [ ! -d "$DOTFILES_DIR" ]; then
              echo "Cloning dotfiles repository..."
              sudo -u shardul git clone https://github.com/shardulbee/dotfiles.git "$DOTFILES_DIR"
            fi

            # Run dotfile symlink installation if the repository exists
            if [ -d "$DOTFILES_DIR" ] && [ -f "$DOTFILES_DIR/Makefile.dotfiles" ]; then
              echo "Setting up dotfile symlinks..."
              cd "$DOTFILES_DIR" && sudo -H -u shardul make -f Makefile.dotfiles install
            fi
          '';

          # Set Git commit hash for darwin-version
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility
          system.stateVersion = 5;

          # The platform the configuration will be used on
          nixpkgs.hostPlatform = "aarch64-darwin";

          # Users configuration
          users.users.shardul = {
            name = "shardul";
            home = "/Users/shardul";
            shell = pkgs.fish;
          };

          # Home Manager configuration
          home-manager.backupFileExtension = "backup";
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.shardul =
            { ... }:
            {
              home.stateVersion = "23.05";
            };
        };
    in
    {
      darwinConfigurations."turbochardo" = nix-darwin.lib.darwinSystem {
        modules = [
          (mkDarwinConfiguration "turbochardo")
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
        ];
      };

      darwinConfigurations."baricbook" = nix-darwin.lib.darwinSystem {
        modules = [
          (mkDarwinConfiguration "baricbook")
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
        ];
      };

      # NixOS configuration for LXC container
      nixosConfigurations.proxmox-lxc = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          home-manager.nixosModules.home-manager
          (
            { modulesPath, pkgs, ... }:
            {
              imports = [ (modulesPath + "/virtualisation/proxmox-lxc.nix") ];

              system.stateVersion = "24.11";

              proxmoxLXC = {
                manageNetwork = false;
                privileged = false;
              };

              nix.settings.sandbox = false;

              # Disable documentation to avoid man-cache build issues in container
              documentation.enable = false;
              documentation.nixos.enable = false;
              documentation.man.enable = false;
              documentation.info.enable = false;
              documentation.doc.enable = false;

              networking.hostName = "nixos";

              nix.settings.experimental-features = [
                "nix-command"
                "flakes"
              ];

              nixpkgs.config.allowUnfree = true;

              environment.systemPackages = with pkgs; [
                bat
                fd
                fzf
                gh
                git
                jq
                neovim
                ripgrep
                zoxide
                direnv
                mise
                age
                uv
                jujutsu
                jjui.packages.${pkgs.system}.default
                hyperfine
                wget
                tmux
                atuin

                # Development tools
                gnumake
                openssh
                curl
                htop
              ];

              services.openssh.enable = true;
              services.tailscale.enable = true;

              # User configuration
              users.users.shardul = {
                isNormalUser = true;
                extraGroups = [ "wheel" ];
                shell = pkgs.fish;
              };

              # Enable fish shell
              programs.fish.enable = true;

              # Post-activation script to set up dotfiles
              system.activationScripts.dotfiles = {
                text = ''
                  DOTFILES_DIR="/home/shardul/Documents/dotfiles"

                  # Clone or update dotfiles repository if needed
                  if [ ! -d "$DOTFILES_DIR" ]; then
                    echo "Cloning dotfiles repository..."
                    sudo -u shardul git clone https://github.com/shardulbee/dotfiles.git "$DOTFILES_DIR"
                  fi

                  # Run dotfile symlink installation if the repository exists
                  if [ -d "$DOTFILES_DIR" ] && [ -f "$DOTFILES_DIR/Makefile.dotfiles" ]; then
                    echo "Setting up dotfile symlinks..."
                    cd "$DOTFILES_DIR" && sudo -u shardul make -f Makefile.dotfiles install
                  fi
                '';
                deps = [];
              };

              # Home Manager configuration
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.shardul =
                  { ... }:
                  {
                    home.stateVersion = "24.11";

                    # Git configuration
                    programs.git.enable = true;
                    home.file = {
                      ".hushlogin" = {
                        text = "";
                      };

                      # Create Documents directory
                      "Documents/.keep" = {
                        text = "";
                      };
                    };

                    # Programs configuration
                    programs.fzf = {
                      enable = true;
                      enableFishIntegration = true;
                    };

                    programs.zoxide = {
                      enable = true;
                      enableFishIntegration = true;
                    };

                    programs.atuin = {
                      enable = true;
                      enableFishIntegration = true;
                    };

                    programs.bat.enable = true;
                  };
              };
            }
          )
        ];
      };
    };
}
