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
  security.pam.services.swaylock = { };
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
    fuzzel
    ghostty
    glib
    jq
    libnotify
    lxqt.lxqt-policykit
    mako
    swaybg
    swayidle
    swaylock
    waybar
    wl-clipboard
    wtype
    xwayland-satellite
  ];
}
