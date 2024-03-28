# vim: fdm=marker fdl=0
{ pkgs, ... }: let
  stow = pkgs.stow;
  zsh-autosuggestions = pkgs.zsh-autosuggestions;
  zsh-fast-syntax-highlighting = pkgs.zsh-fast-syntax-highlighting;
  fzf = pkgs.fzf;
  direnv = pkgs.direnv;
in {
  environment.pathsToLink = [ "/share/zsh" ];
  nix = {
    useDaemon = true;
    nixPath = [
      { nixpkgs = "${pkgs.path}"; }
    ];
  };
  services.nix-daemon.enable = true;
  nixpkgs.hostPlatform = "aarch64-darwin";
  nix.settings.experimental-features = "nix-command flakes";
  system.stateVersion = 4;
  nixpkgs.config.allowUnfree = true;

# {{{ programs
  environment.systemPackages =
    [ pkgs.vim
      pkgs.git
      pkgs.fd
      pkgs.jq
      pkgs.bat
      pkgs.gh
      pkgs.rnix-lsp
      pkgs.sumneko-lua-language-server
      pkgs.go
      pkgs.ocamlPackages.ocaml-lsp
      pkgs.ocamlformat
      pkgs.ruby
      pkgs.nodejs
      pkgs.nodePackages.fixjson
      pkgs.nodePackages.jsonlint
      pkgs.stylua
      pkgs.neofetch
      pkgs.rubyPackages.solargraph
      pkgs.wget
      pkgs._1password
      pkgs.stow
      pkgs.ripgrep
      pkgs.neovim
      pkgs.darwin.trash
      pkgs.tree-sitter
      pkgs.kitty
      pkgs.cargo
      pkgs.rustc
      pkgs.rust-analyzer
      pkgs.clippy
      pkgs.rustfmt
      pkgs.fish
      pkgs.flyctl
      pkgs.hyperfine
      pkgs.httpie
      pkgs.rclone
      pkgs.tarsnap
      pkgs.hugo
      pkgs.railway

      direnv
      zsh-autosuggestions
      zsh-fast-syntax-highlighting
      fzf
  ];

  programs.zsh = {
    enable = true;
    enableBashCompletion = false;
    enableCompletion = false;
    promptInit = "";
    interactiveShellInit = ''
      source ${zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
      source ${zsh-fast-syntax-highlighting}/share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh
      source ${fzf}/share/fzf/key-bindings.zsh

      direnv() {
        if command -v /usr/local/bin/direnv > /dev/null; then
          eval "$(${direnv} hook zsh)"
          /usr/local/bin/direnv "$@"
        else
          echo "direnv not found"
          return 1
        fi
      }
    '';
  };
# }}}

  # {{{ macos defaults

  # use touch ID for sudo
  security.pam.enableSudoTouchIdAuth = true;

# {{{ keyboard
  system.keyboard.enableKeyMapping = true;
  system.defaults.NSGlobalDomain.InitialKeyRepeat = 15;
  system.defaults.NSGlobalDomain.KeyRepeat = 1;
  system.defaults.NSGlobalDomain.NSAutomaticCapitalizationEnabled = false;
  system.defaults.NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false;
  system.defaults.NSGlobalDomain.NSDocumentSaveNewDocumentsToCloud = false;
  system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode = true;
  system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled = false;
  system.defaults.NSGlobalDomain.AppleKeyboardUIMode = 3;
  system.keyboard.remapCapsLockToControl = true;
  system.defaults.NSGlobalDomain."com.apple.keyboard.fnState" = false;
  system.defaults.NSGlobalDomain."com.apple.mouse.tapBehavior" = 1;
  system.defaults.NSGlobalDomain."com.apple.trackpad.trackpadCornerClickBehavior" = 1;
# }}}

# {{{ dock/finder/appearance
  system.defaults.dock.mru-spaces = false;
  system.defaults.dock.minimize-to-application = true;
  system.defaults.dock.mineffect = "scale";
  system.defaults.dock.launchanim = false;
  system.defaults.dock.expose-animation-duration = 0.0;
  system.defaults.dock.orientation = "bottom";
  system.defaults.dock.show-recents = false;
  system.defaults.dock.static-only = true;
  system.defaults.finder.CreateDesktop = false;
  system.defaults.finder.FXPreferredViewStyle = "Nlsv";
  system.defaults.finder.ShowPathbar = true;
  system.defaults.NSGlobalDomain.AppleInterfaceStyle = "Dark";
  system.defaults.menuExtraClock.Show24Hour = true;
# }}}
  # }}}

# {{{ homebrew
  homebrew = {
    enable = true;
    brews = [
      "mas"
      "opam"
    ];
    casks = [
      "1password"
      "arq"
      "bartender"
      "cleanshot"
      "dash"
      "hammerspoon"
      "google-chrome"
      "istat-menus"
      "raycast"
      "sublime-merge"
      "thingsmacsandboxhelper"
      "vlc"
      "zwift"
      "spotify"
      "zoom"
      "orbstack"
      "balenaetcher"
      "tailscale"
      "zed"
      "focus"
      "google-drive"
      "fantastical"
      "zulip"
      "cursor"
    ];
    masApps = {
      "Things 3" = 904280696;
      "iA Writer" = 775737590;
      "CARROT Weather" = 993487541;
    };
    onActivation.cleanup = "uninstall";
  };
# }}}

  networking.hostName = "turbochardo";
  networking.localHostName = "turbochardo";
  networking.computerName = "turbochardo";

  users.users.shardul = {
    name = "shardul";
    home = "/Users/shardul";
    isHidden = false;
    shell = pkgs.zsh;
  };
  system.activationScripts.postActivation.text = ''
    $DRY_RUN_CMD ln -sfn /run/current-system/sw/bin/* /usr/local/bin
    $DRY_RUN_CMD ln -sfn /run/current-system/sw/lib/* /usr/local/lib
    $DRY_RUN_CMD ${stow}/bin/stow --ignore=\.DS_Store -R --dotfiles --target=/Users/shardul home
  '';
}
