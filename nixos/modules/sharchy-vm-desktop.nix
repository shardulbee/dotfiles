{ pkgs, ... }:

{
  hardware.graphics.enable = true;
  virtualisation.vmware.guest = {
    enable = true;
    headless = true;
    package = pkgs.open-vm-tools;
  };

  # The upstream mount unit passes the FUSE binary to mount(8) as a source,
  # which fails with Fusion 26H1. Start vmblock-fuse directly instead.
  systemd.services.vmblock-fuse = {
    description = "VMware vmblock FUSE mount";
    wantedBy = [ "multi-user.target" ];
    before = [ "vmware.service" ];
    unitConfig.ConditionVirtualization = "vmware";
    serviceConfig = {
      Type = "forking";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /run/vmblock-fuse";
      ExecStart = "${pkgs.open-vm-tools}/bin/vmware-vmblock-fuse -o subtype=vmware-vmblock,default_permissions,allow_other /run/vmblock-fuse";
      ExecStop = "${pkgs.util-linux}/bin/umount /run/vmblock-fuse";
    };
  };

  security.wrappers.vmware-user-suid-wrapper = {
    setuid = true;
    owner = "root";
    group = "root";
    source = "${pkgs.open-vm-tools}/bin/vmware-user-suid-wrapper";
  };

  services.xserver = {
    enable = true;
    displayManager = {
      lightdm.enable = true;
      sessionCommands = "${pkgs.open-vm-tools}/bin/vmware-user-suid-wrapper";
    };
    windowManager.i3.enable = true;
    xkb.options = "ctrl:nocaps";
  };
  services.displayManager = {
    autoLogin = {
      enable = true;
      user = "shardul";
    };
    defaultSession = "none+i3";
  };
  services.libinput.touchpad.naturalScrolling = true;

  programs.dconf.enable = true;
  security.polkit.enable = true;
  services.dbus.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  environment.systemPackages = with pkgs; [
    chromium
    dunst
    feh
    ghostty
    i3status
    lxqt.lxqt-policykit
    rofi
    xclip
    xdotool
    xterm
  ];
}
