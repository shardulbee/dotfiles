{ config, pkgs, ... }:

{
  imports = [
    ../../modules/sharchy-desktop.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "sharchy";
  time.timeZone = "America/Montreal";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.shardul = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
  services.tailscale.enable = true;
  networking.networkmanager.enable = true;

  fonts.packages = with pkgs; [
    jetbrains-mono
    nerd-fonts.jetbrains-mono
  ];

  environment.systemPackages = with pkgs; [
    curl
    git
    mise
    ripgrep
    vim
    wget
  ];

  system.stateVersion = "26.05";
}
