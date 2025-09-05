{ pkgs, config, lib, ... }:
{
  nixpkgs.config.allowUnfree = true;

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
    ];
    masApps = {
      "Things 3" = 904280696;
    };
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = false;
    onActivation.upgrade = false;
  };

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

    # Run dotfile symlink installation if the repository exists
    DOTFILES_DIR="/Users/shardul/Documents/dotfiles"
    if [ -d "$DOTFILES_DIR" ] && [ -f "$DOTFILES_DIR/Makefile.dotfiles" ]; then
      echo "Setting up dotfile symlinks..."
      cd "$DOTFILES_DIR" && sudo -u shardul make -f Makefile.dotfiles install
    fi
  '';

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
}