{ pkgs, inputs, lib, ... }:
let
  stow = pkgs.stow;
  zsh-autosuggestions = pkgs.zsh-autosuggestions;
  zsh-fast-syntax-highlighting = pkgs.zsh-fast-syntax-highlighting;
  fzf = pkgs.fzf;
  fzf-git-sh = pkgs.fzf-git-sh;
  pkgs = import inputs.nixpkgs {
    system = "aarch64-darwin";
    config = {
      allowUnfreePredicate = _: true;
    };
  };

  commonPackages = [
    zsh-autosuggestions
    zsh-fast-syntax-highlighting
    fzf
    pkgs.neovim
    pkgs.git
    pkgs.fd
    pkgs.jq
    pkgs.bat
    pkgs.gh
    pkgs.ripgrep
    pkgs.darwin.trash
    pkgs.zoxide
    pkgs.delta
  ];

  commonCasks = [
    "1password"
    "hammerspoon"
    "google-chrome"
    "raycast"
    "spotify"
    "zoom"
    "zed"
    "nikitabobko/tap/aerospace"
    "karabiner-elements"
    "obsidian"
  ];
in
{
  users.users.shardul = {
    name = "shardul";
    home = "/Users/shardul";
    isHidden = false;
    shell = pkgs.zsh;
  };

  environment.systemPackages = [
    pkgs.asdf
  ] ++ commonPackages;

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
    global.autoUpdate = true;
    brews = [
    ];
    casks = [
      "zwift"
      "tailscale"
      "vlc"
      "cleanshot"
      "arq"
      "fantastical"
      "google-drive"
    ] ++ commonCasks;
    onActivation.cleanup = "uninstall";
  };
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

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

  networking.hostName = "turbochardo";
  networking.localHostName = "turbochardo";
  networking.computerName = "turbochardo";

  security.pam.enableSudoTouchIdAuth = true;
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
    $DRY_RUN_CMD ${stow}/bin/stow --ignore=\.DS_Store -R --no-folding --dotfiles --target=/Users/shardul home
  '';
}
