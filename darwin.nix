# vim: fdm=marker fdl=0
{ pkgs, ... }: let
  stow = pkgs.stow;
  zsh-autosuggestions = pkgs.zsh-autosuggestions;
  zsh-fast-syntax-highlighting = pkgs.zsh-fast-syntax-highlighting;
  fzf = pkgs.fzf;
  fzf-git-sh = pkgs.fzf-git-sh;
  # neovimConfig = pkgs.neovimUtils.makeNeovimConfig {
  #   withNodeJs = true;
  #   withRuby = true;
  #   withPython3 = true;
  #   wrapRc = false;
  # };
  # fullConfig = (neovimConfig // {
  #   wrapperArgs = pkgs.lib.escapeShellArgs neovimConfig.wrapperArgs;
  # });
  # neovim-custom = pkgs.wrapNeovimUnstable
  #   (pkgs.neovim-unwrapped.overrideAttrs (oldAttrs: {
  #     buildInputs = oldAttrs.buildInputs ++ [ pkgs.tree-sitter ];
  #   })) fullConfig;
in {

  users.users.shardul = {
    name = "shardul";
    home = "/Users/shardul";
    isHidden = false;
    shell = pkgs.zsh;
  };

  # -------------------------------------------------------
  # Programs/packages
  # -------------------------------------------------------
  environment.systemPackages =
    [ pkgs.vim
      pkgs.neovim
      pkgs.git
      pkgs.fd
      pkgs.jq
      pkgs.bat
      pkgs.gh
      pkgs.neofetch
      pkgs.wget
      pkgs._1password
      pkgs.ripgrep
      pkgs.darwin.trash
      pkgs.kitty
      pkgs.hyperfine
      pkgs.tarsnap
      stow
      zsh-autosuggestions
      zsh-fast-syntax-highlighting
      fzf
      # pkgs.direnv
      # pkgs.git-lfs
      # neovim-custom
      # pkgs.jankyborders
      # pkgs.tree
      # pkgs.google-cloud-sdk
      # pkgs.mutagen
      # pkgs.markdown-anki-decks
  ];

  programs.zsh = {
    enable = true;
    enableBashCompletion = false;
    enableCompletion = false;
    promptInit = "";
    interactiveShellInit = ''
      source ${zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
      source ${zsh-fast-syntax-highlighting}/share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh
      source ${fzf}/share/fzf/completion.zsh
      source ${fzf}/share/fzf/key-bindings.zsh
      source ${fzf-git-sh}/share/fzf-git-sh/fzf-git.sh
    '';
  };
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    loadInNixShell = true;
  };

  homebrew = {
    enable = true;
    brews = [
      "mas"
      "opam"
      # "gnu-time"
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
      "thingsmacsandboxhelper"
      "vlc"
      "spotify"
      "zoom"
      "tailscale"
      "google-drive"
      "fantastical"
      # "zwift"
      # "orbstack"
      # "visual-studio-code"
      # "anki"
      # "zed"
      # "whatsapp"
      # "clion"
      # "opal-composer"
    ];
    masApps = {
      "Things 3" = 904280696;
      "Infuse • Video Player" = 1136220934;
      "Control Panel for Twitter" = 1668516167;
      # "iA Writer" = 775737590;
    };
    onActivation.cleanup = "uninstall";
  };
  fonts.fontDir.enable = true;
  fonts.fonts = with pkgs; [
    recursive
    (nerdfonts.override {
      fonts = [ "IBMPlexMono" ];
    })
  ];

  # {{{ misc environment
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

  networking.hostName = "turbochardo";
  networking.localHostName = "turbochardo";
  networking.computerName = "turbochardo";
  #}}}

  #{{{ macos defaults
  security.pam.enableSudoTouchIdAuth = true;

  # ------------------------------------------------------------
  # Keyboard
  # ------------------------------------------------------------
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

  # ------------------------------------------------------------
  # dock/finder/appearance
  # ------------------------------------------------------------
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

  system.activationScripts.postActivation.text = ''
    $DRY_RUN_CMD ln -sfn /run/current-system/sw/bin/* /usr/local/bin
    $DRY_RUN_CMD ln -sfn /run/current-system/sw/lib/* /usr/local/lib
    $DRY_RUN_CMD ${stow}/bin/stow --ignore=\.DS_Store -R --dotfiles --target=/Users/shardul home
  '';
}
