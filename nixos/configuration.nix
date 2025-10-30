{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.shardul = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.fish;
  };

  programs.fish.enable = true;

  security.sudo.wheelNeedsPassword = false;

  networking = {
    networkmanager.enable = true;
    hostName = "nixos";
  };

  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  environment.systemPackages = with pkgs; [
    # Terminal & Shell
    ghostty
    fish
    tmux

    # Wayland essentials
    wofi
    waybar
    dunst
    wl-clipboard
    grim
    slurp

    # Core tools
    git
    jujutsu
    neovim
    curl
    wget
    ripgrep
    fd
    fzf
    htop
    unzip

    # Fonts
    (nerdfonts.override { fonts = [ "CascadiaCode" ]; })
  ];

  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "CascadiaCode" ]; })
  ];

  system.stateVersion = "24.05";
}
