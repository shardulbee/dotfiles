{ pkgs, ... }:

{
  programs.hyprland.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        user = "shardul";
        command = "Hyprland";
      };
      default_session = {
        user = "shardul";
        command = "Hyprland";
      };
    };
  };

  programs.dconf.enable = true;
  security.polkit.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
  };

  environment.systemPackages = with pkgs; [
    chromium
    ghostty
    glib
    jq
    awww
    wl-clipboard
    wtype
    xdg-utils
  ];
}
