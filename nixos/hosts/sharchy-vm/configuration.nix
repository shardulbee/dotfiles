{ pkgs, ... }:

{
  imports = [
    ../../modules/sharchy-vm-desktop.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "sharchy-vm";
  networking.networkmanager = {
    enable = true;
    insertNameservers = [ "1.1.1.1" "8.8.8.8" ];
  };
  time.timeZone = "America/Montreal";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.shardul = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
    initialHashedPassword = "$6$sharchyvm$aPsveEeR3VaZLNsIsZyLV8EXv/fqt.xaLQQNxUXQWIsKjg9Zx5DYEaEfL.x4.cwJ3vVlIimbrHHbtAjtC91F61";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJyBr8fJpesCNZcxU+hDSBSUy34p8Z7VRRSctN2DYHqF shardul@gadget"
    ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
  security.sudo.wheelNeedsPassword = false;
  services.openssh.enable = true;

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
