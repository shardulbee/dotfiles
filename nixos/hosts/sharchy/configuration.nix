{ config, pkgs, ... }:

{
  imports = [
    ../../modules/sharchy-desktop.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "sharchy";
  time.timeZone = "America/Montreal";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.enableRedistributableFirmware = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  users.users.shardul = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJyBr8fJpesCNZcxU+hDSBSUy34p8Z7VRRSctN2DYHqF shardul@gadget"
    ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
  services.tailscale.enable = true;
  networking.networkmanager.enable = true;

  services.fstrim.enable = true;
  services.fwupd.enable = true;
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;
  zramSwap.enable = true;

  fonts.packages = with pkgs; [
    jetbrains-mono
    nerd-fonts.jetbrains-mono
  ];

  environment.systemPackages = with pkgs; [
    btrfs-progs
    cryptsetup
    curl
    git
    mise
    pciutils
    ripgrep
    usbutils
    vim
    wget
  ];

  system.stateVersion = "26.05";
}
