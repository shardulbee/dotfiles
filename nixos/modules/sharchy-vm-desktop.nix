{ config, pkgs, ... }:

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

  programs.niri.enable = true;
  services.clipway = {
    enable = true;
    target = "niri.service";
  };
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${config.programs.niri.package}/bin/niri-session";
      user = "shardul";
    };
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

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
    adwaita-icon-theme
    (chromium.override {
      commandLineArgs = "--ozone-platform=wayland --ozone-platform-hint=wayland --password-store=basic --enable-features=TouchpadOverscrollHistoryNavigation --load-extension=/home/shardul/.config/chromium/extensions/alt-click-new-tab";
    })
    fuzzel
    ghostty
    jq
    lxqt.lxqt-policykit
    mako
    swaybg
    waybar
    wl-clipboard
    wtype
    xwayland-satellite
  ];
}
