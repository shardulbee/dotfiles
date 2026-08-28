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
    settings.default_session.user = "greeter";
  };
  programs.noctalia-greeter = {
    enable = true;
    greeter-args = "--user shardul --session 'Hyprland (uwsm-managed)'";
    settings = {
      session.default = "Hyprland (uwsm-managed)";
      user.default = "shardul";
      appearance = {
        scheme = "Noctalia";
        password_style = "default";
        hide_logo = true;
        theme_mode = "dark";
        corner_radius_scale = 1.0;
        font_family = "JetBrainsMono Nerd Font";
      };
      output = {
        name = "eDP-1";
        width = 2560;
        height = 1600;
        scale = 2.0;
      };
      cursor = {
        theme = "Adwaita";
        size = 24;
      };
      keyboard = {
        layout = "us";
        options = "ctrl:nocaps";
        numlock = true;
      };
      idle.timeout = 300;
    };
  };

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
