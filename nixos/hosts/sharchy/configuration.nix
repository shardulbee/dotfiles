{ config, pkgs, ... }:

{
  imports = [
    ../../modules/sharchy-desktop.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "sharchy";
  time.timeZone = "America/Montreal";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.consoleLogLevel = 0;
  # Xe reports failed PSR2 selective-fetch calculations on this panel; disable
  # that optimization while keeping the rest of panel self-refresh enabled.
  boot.kernelParams = [ "xe.enable_psr2_sel_fetch=0" ];
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
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "shardul" ];
  };
  programs.helium = {
    enable = true;
    policies = {
      PasswordManagerEnabled = false;
      BrowserColorScheme = "device";
      ExtensionInstallForcelist = [
        "dbepggeogbaibhgnhhndojpepiihcmeb;https://clients2.google.com/service/update2/crx"
        "aeblfdkhhhdcdjpifhhbdiojplfjncoa;https://clients2.google.com/service/update2/crx"
      ];
    };
  };
  environment.etc."1password/custom_allowed_browsers".text = "helium\n";
  environment.localBinInPath = true;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
  services.tailscale.enable = true;
  networking.networkmanager.enable = true;

  services.fstrim.enable = true;
  services.fwupd.enable = true;
  services.power-profiles-daemon.enable = true;
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
    pciutils
    ripgrep
    usbutils
    vim
    wget
  ];

  system.stateVersion = "26.05";
}
