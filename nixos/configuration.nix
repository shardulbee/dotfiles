# Minimal NixOS configuration
#
# Install: sudo nixos-rebuild switch
# Dotfiles: Run ./setup from repo root

{ pkgs, lib, ... }:

{
  imports = lib.optional (builtins.pathExists /etc/nixos/hardware-configuration.nix)
    /etc/nixos/hardware-configuration.nix;

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  users.users.shardul = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.fish;
  };

  programs.fish.enable = true;
  programs.niri.enable = true;

  services.greetd = {
    enable = true;
    settings.default_session.command = "${pkgs.greetd.tuigreet}/bin/tuigreet --cmd niri-session";
  };

  security.sudo.wheelNeedsPassword = false;

  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  services.blueman.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  };

  fonts.packages = with pkgs; [
    nerd-fonts.caskaydia-mono
  ];

  environment.systemPackages = with pkgs; [
    ghostty fuzzel wl-clipboard
    git jujutsu neovim ripgrep fd fzf
    swww hyprlock waybar
    pavucontrol blueman networkmanagerapplet btop
    chromium _1password _1password-cli
    gcc zoxide atuin
  ];

  system.stateVersion = "24.05";
}
