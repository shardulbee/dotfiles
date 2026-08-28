{ config, pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt
    ];
  };

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
        scheme = "Synced";
        password_style = "default";
        hide_logo = true;
        theme_mode = "dark";
        corner_radius_scale = 0.5;
        font_family = "JetBrainsMono Nerd Font";
        palette = {
          primary = "#d8e8ff";
          on_primary = "#062d70";
          secondary = "#9fc5ff";
          on_secondary = "#062d70";
          tertiary = "#b8d6ff";
          on_tertiary = "#062d70";
          error = "#ffb4ab";
          on_error = "#690005";
          surface = "#063b8e";
          on_surface = "#f4f7ff";
          surface_variant = "#0a438f";
          on_surface_variant = "#d8e8ff";
          outline = "#88aee8";
          shadow = "#031b43";
          hover = "#d8e8ff";
          on_hover = "#062d70";
        };
        wallpaper = {
          path = "color:#063b8e";
          fill_mode = "stretch";
          fill_color = "#063b8e";
        };
      };
      output = {
        name = "eDP-1";
        width = 2560;
        height = 1600;
        scale = 2.0;
      };
      cursor = {
        theme = "macOS";
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
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
    config.common.default = [ "hyprland" "gtk" ];
  };
  security.polkit = {
    enable = true;
    enablePkexecWrapper = true;
  };
  security.pam.services.hyprlock = { };
  security.pam.services.greetd.enableGnomeKeyring = true;
  services.dbus.enable = true;
  services.gnome.gnome-keyring.enable = true;
  services.upower.enable = true;
  services.blueman.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  environment.systemPackages = with pkgs; [
    adwaita-icon-theme
    apple-cursor
    brightnessctl
    blueman
    chromium
    fuzzel
    ghostty
    grim
    hyprlock
    glib
    jq
    libnotify
    lxqt.lxqt-policykit
    mako
    networkmanagerapplet
    pavucontrol
    quickshell
    slurp
    swaybg
    swayidle
    wl-clipboard
  ];
}
