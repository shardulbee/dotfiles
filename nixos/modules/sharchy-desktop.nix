{ config, pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt
    ];
  };

  programs.niri.enable = true;
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };
  programs.uwsm.enable = true;
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --sessions /run/current-system/sw/share/wayland-sessions";
      user = "greeter";
    };
  };
  systemd.tmpfiles.rules = [ "d /var/cache/tuigreet 0755 greeter greeter -" ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  programs.dconf.enable = true;
  programs.nix-ld.enable = true;
  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    recommendedServices.enable = true;
  };
  security.polkit.enable = true;
  security.pam.services.swaylock = { };
  security.pam.services.greetd.enableGnomeKeyring = true;
  services.dbus.enable = true;
  services.gnome.gnome-keyring.enable = true;
  services.upower.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  environment.systemPackages = with pkgs; [
    adwaita-icon-theme
    brightnessctl
    chromium
    fuzzel
    ghostty
    glib
    jq
    libnotify
    lxqt.lxqt-policykit
    swaybg
    swayidle
    swaylock
    wl-clipboard
    wtype
    xwayland-satellite
  ];
}
