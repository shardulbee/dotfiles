{
  description = "Shardul's NixOS and macOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helium = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xremap-flake = {
      url = "github:xremap/nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hermes.url = "github:NousResearch/hermes-agent/29112bef099274229cadff79cdff7bf7b99c4b77";
  };

  outputs = { self, nixpkgs, home-manager, darwin, helium, xremap-flake, hermes, ... }:
    let
      orbDeploy =
        host:
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in
        pkgs.writeShellApplication {
          name = "orb-deploy-${host}";
          runtimeInputs = [
            pkgs.git
            pkgs.openssh
            pkgs.tailscale
          ];
          text = ''
            exec ${pkgs.python3}/bin/python3 -I ${./scripts/orb-deploy.py} ${host} "$@"
          '';
        };
      sharedHome = { pkgs, ... }:
        let
          playwriter = pkgs.callPackage ./packages/playwriter.nix { };
          uberstat = pkgs.callPackage ./packages/uberstat.nix { };
          gr = pkgs.writeShellApplication {
            name = "gr";
            runtimeInputs = [ pkgs.fzf pkgs.neovim pkgs.bashInteractive ];
            text = builtins.readFile ./scripts/gr;
          };
          rebuild = pkgs.writeShellScriptBin "rebuild" ''
            if [ "$(uname)" = Darwin ]; then
              exec sudo darwin-rebuild switch --flake "$HOME/Documents/dotfiles#macbook"
            else
              exec sudo /run/current-system/sw/bin/flock \
                /run/lock/sharchy-deploy.lock \
                /run/current-system/sw/bin/nixos-rebuild switch \
                --flake "$HOME/Documents/dotfiles#sharchy"
            fi
          '';
        in
        {
          home.username = "shardul";
          home.stateVersion = "26.05";
          programs.home-manager.enable = true;
          programs.btop = {
            enable = true;
            settings = {
              proc_aggregate = true;
              proc_tree_auto_collapse = 1;
            };
          };

          home.packages = with pkgs; [
            amp-cli
            atuin
            claude-code
            direnv
            fd
            fish
            fzf
            gh
            go_1_27
            gr
            hyperfine
            jjui
            jq
            jujutsu
            neovim
            nodejs_26
            pi-coding-agent
            playwriter
            rclone
            rebuild
            ripgrep
            tmux
            trash-cli
            tree-sitter
            uberstat
            usage
            uv
            yazi
            yt-dlp
            zoxide
            zsh-autosuggestions
          ];

          home.sessionVariables = {
            DISABLE_AUTOUPDATER = "1";
            UBERSTAT_ROOT = "$HOME/Documents";
          };
          home.sessionPath = [ "$HOME/.local/bin" ];

          home.file.".zshrc".source = ./config/zsh.zsh;
          xdg.configFile."fish/config.fish".source = ./config/fish.fish;
          xdg.configFile."git/config".text = ''
      [init]
      	defaultBranch = "main"
      
      [user]
      	name = "Shardul Baral"
      	email = "16765155+shardulbee@users.noreply.github.com"
      [credential "https://github.com"]
      	helper = 
      	helper = !gh auth git-credential
      [credential "https://gist.github.com"]
      	helper = 
      	helper = !gh auth git-credential
    '';
          xdg.configFile."git/ignore".text = ''
      # macOS
      .DS_Store
      .git/
      .direnv/
    '';
          xdg.configFile."jj/config.toml".text = ''
      [user]
      name = "Shardul Baral"
      email = "16765155+shardulbee@users.noreply.github.com"
      
      [ui]
      default-command = 'log'
      
      [revset-aliases]
      'closest_bookmark(to)' = 'heads(::to & bookmarks())'
      
      [aliases]
      # Move the closest bookmark to the current commit. Useful when working on a
      # named branch, creating a bunch of commits, and then needing to update the
      # bookmark before pushing.
      tug = ["bookmark", "move", "--from", "closest_bookmark(@-)", "--to", "@-"]
      
      [template-aliases]
      'format_timestamp(timestamp)' = 'timestamp.ago()'
    '';
          xdg.configFile."jjui/config.lua".source = ./config/jjui.lua;
          xdg.configFile."nvim/init.lua".source = ./config/nvim.lua;
          xdg.configFile."nvim/colors/alabaster.lua".source = ./config/nvim-alabaster.lua;
          xdg.configFile."tmux/tmux.conf".source = ./config/tmux.conf;
          xdg.configFile."ghostty/themes/Alabaster Light".text = ''
      # Alabaster Light - based on tonsky/sublime-scheme-alabaster
      # https://github.com/tonsky/sublime-scheme-alabaster
      
      background = #f7f7f4
      foreground = #26251e
      cursor-color = #007acc
      cursor-text = #f7f7f4
      selection-background = #bfdbfe
      selection-foreground = #26251e
      
      # black
      palette = 0=#26251e
      palette = 8=#777777
      
      # red
      palette = 1=#aa3731
      palette = 9=#f05050
      
      # green
      palette = 2=#448c27
      palette = 10=#60cb00
      
      # yellow
      palette = 3=#cb9000
      palette = 11=#ffbc5d
      
      # blue
      palette = 4=#325cc0
      palette = 12=#007acc
      
      # magenta
      palette = 5=#7a3e9d
      palette = 13=#e64ce6
      
      # cyan
      palette = 6=#0083b2
      palette = 14=#00aacb
      
      # white
      palette = 7=#bbbbbb
      palette = 15=#ffffff
    '';
          xdg.configFile."ghostty/themes/Alabaster Dark".text = ''
      # Alabaster Dark - based on tonsky/sublime-scheme-alabaster
      # https://github.com/tonsky/sublime-scheme-alabaster
      
      background = #14120b
      foreground = #cecece
      cursor-color = #cd974b
      cursor-text = #14120b
      selection-background = #3a382f
      selection-foreground = #cecece
      
      # black
      palette = 0=#14120b
      palette = 8=#777777
      
      # red
      palette = 1=#d66a64
      palette = 9=#e47e78
      
      # green
      palette = 2=#8fb980
      palette = 10=#a5ca98
      
      # yellow
      palette = 3=#c7a55f
      palette = 11=#d5b773
      
      # blue
      palette = 4=#739fc8
      palette = 12=#8bb2d5
      
      # magenta
      palette = 5=#b986b5
      palette = 13=#c99bc5
      
      # cyan
      palette = 6=#6faeb3
      palette = 14=#88c0c4
      
      # white
      palette = 7=#cecece
      palette = 15=#ffffff
    '';
          xdg.configFile."zed/settings.json".source = ./config/zed-settings.json;
          xdg.configFile."zed/keymap.json".source = ./config/zed-keymap.json;
          xdg.configFile."zed/tasks.json".source = ./config/zed-tasks.json;
          xdg.configFile."zed/themes/soft.json".source = ./config/zed-soft.json;
        };
    in
    {
      apps.x86_64-linux.orb-deploy-sharchy = {
        type = "app";
        program = "${orbDeploy "sharchy"}/bin/orb-deploy-sharchy";
      };

      apps.x86_64-linux.orb-deploy-turbogadget = {
        type = "app";
        program = "${orbDeploy "turbogadget"}/bin/orb-deploy-turbogadget";
      };

      nixosConfigurations.sharchy = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit hermes; };
        modules = [
          ./hosts/sharchy.nix
          (import ./config/github-sync.nix { linux = true; })
          home-manager.nixosModules.home-manager
          helium.nixosModules.default
          xremap-flake.nixosModules.default
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-backup";
            home-manager.users.shardul.imports = [ sharedHome ];
          }
        ];
      };

      darwinConfigurations.macbook = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./config/turbogadget-deploy.nix
          (import ./config/github-sync.nix { linux = false; })
          home-manager.darwinModules.home-manager
          ({ pkgs, ... }: {
            nixpkgs.config.allowUnfree = true;
            nix.enable = false; # Determinate Nix owns the daemon and nix.conf.
            system.primaryUser = "shardul";
            system.stateVersion = 6;
            users.users.shardul.home = "/Users/shardul";
            users.users.shardul.openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDvyyQaeYRafexqIO6kZByqrYMB9IrumIez6BsZDuOJr shardul@sharbox"
            ];

            programs.zsh.enable = true;
            environment.shells = [ pkgs.fish ];
            security.pam.services.sudo_local = {
              touchIdAuth = true;
              reattach = true;
            };

            # Install a real file before launchd loads the agent. A store symlink
            # cannot run the wait when /nix/store has not mounted yet.
            # Rebuild only when restarting the runner is safe. After activation,
            # check com.ampcode.runner in sfltool dumpbtm and Login Items.
            # macOS may cache old names; do not reset the whole BTM database.
            system.activationScripts.extraActivation.text = ''
              /usr/bin/install -d -m 0755 '/Library/Application Support/Amp Runner'
              /usr/bin/install -m 0755 ${pkgs.writeText "amp-runner-launcher" ''
                #!/bin/sh
                /bin/wait4path /nix/store && exec "$@"
              ''} '/Library/Application Support/Amp Runner/Amp Runner'
            '';

            launchd.user.agents.amp-runner = {
              serviceConfig = {
                Label = "com.ampcode.runner";
                # Login Items uses the executable name, not Label. Avoid the
                # generic /bin/sh wrapper that nix-darwin's command generates.
                # Inherit the login shell's exports, including interactive .zshrc.
                ProgramArguments = [
                  "/Library/Application Support/Amp Runner/Amp Runner"
                  "/bin/zsh" "-ilc" ''exec "$@"'' "amp-runner"
                  "${pkgs.amp-cli}/bin/amp"
                  "--no-tui"
                  "--runner-id" "turbogadget"
                  "--remote-control-terminal"
                ];
                EnvironmentVariables.HOME = "/Users/shardul";
                WorkingDirectory = "/Users/shardul/.local/share/amp/host-runner/turbogadget";
                RunAtLoad = true;
                KeepAlive = true;
                ThrottleInterval = 5;
                StandardOutPath = "/Users/shardul/Library/Logs/amp-runner.log";
                StandardErrorPath = "/Users/shardul/Library/Logs/amp-runner.log";
              };
            };

            launchd.user.agents.amp-runner-chinwag = {
              serviceConfig = {
                Label = "com.ampcode.runner.chinwag";
                # Initialize shell integrations outside Documents to avoid TCC
                # prompts for helpers such as direnv. cd -q skips chpwd hooks.
                ProgramArguments = [
                  "/Library/Application Support/Amp Runner/Amp Runner"
                  "/bin/zsh" "-ilc" ''cd -q -- "$1" && shift && exec "$@"'' "amp-runner"
                  "/Users/shardul/Documents/chinwag"
                  "${pkgs.amp-cli}/bin/amp"
                  "--no-tui"
                  "--runner-id" "chinwag"
                  "--remote-control-terminal"
                ];
                EnvironmentVariables.HOME = "/Users/shardul";
                WorkingDirectory = "/Users/shardul";
                RunAtLoad = true;
                KeepAlive = true;
                ThrottleInterval = 5;
                StandardOutPath = "/Users/shardul/Library/Logs/amp-runner-chinwag.log";
                StandardErrorPath = "/Users/shardul/Library/Logs/amp-runner-chinwag.log";
              };
            };

            launchd.user.agents.amp-runner-natterwire = {
              serviceConfig = {
                Label = "com.ampcode.runner.natterwire";
                ProgramArguments = [
                  "/Library/Application Support/Amp Runner/Amp Runner"
                  "/bin/zsh" "-ilc" ''cd -q -- "$1" && shift && exec "$@"'' "amp-runner"
                  "/Users/shardul/Documents/natterwire"
                  "${pkgs.amp-cli}/bin/amp"
                  "--no-tui"
                  "--runner-id" "natterwire"
                  "--remote-control-terminal"
                ];
                EnvironmentVariables.HOME = "/Users/shardul";
                WorkingDirectory = "/Users/shardul";
                RunAtLoad = true;
                KeepAlive = true;
                ThrottleInterval = 5;
                StandardOutPath = "/Users/shardul/Library/Logs/amp-runner-natterwire.log";
                StandardErrorPath = "/Users/shardul/Library/Logs/amp-runner-natterwire.log";
              };
            };

            system.defaults = {
              dock = {
                autohide = true;
                show-recents = false;
              };
              finder = {
                AppleShowAllExtensions = true;
                FXPreferredViewStyle = "Nlsv";
              };
              NSGlobalDomain = {
                ApplePressAndHoldEnabled = false;
                InitialKeyRepeat = 15;
                KeyRepeat = 1;
              };
            };

            homebrew = {
              enable = true;
              casks = [
                "1password"
                "1password-cli"
                "anki"
                "arq"
                "discord"
                "font-jetbrains-mono-nerd-font"
                "ghostty"
                "google-drive"
                "helium-browser"
                "obsidian"
                "raycast"
                "tailscale-app"
              ];
              onActivation = {
                autoUpdate = false;
                upgrade = false;
                cleanup = "uninstall";
              };
            };

            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-backup";
            home-manager.users.shardul = {
              imports = [ sharedHome ];
              home.homeDirectory = "/Users/shardul";
              home.file.".local/share/amp/host-runner/turbogadget/AGENTS.md".text = ''
                # TurboGadget host runner

                Use this runner for work that requires the TurboGadget host. Do source changes in a project orb unless the task requires macOS or this machine.
              '';
              xdg.configFile."ghostty/config".source = ./config/ghostty-darwin.conf;
            };
          })
        ];
      };
    };
}
