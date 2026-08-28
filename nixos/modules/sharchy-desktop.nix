{ config, pkgs, ... }:

let
  greeterConfig = pkgs.runCommand "sharchy-greeter-config" { } ''
    mkdir -p $out
    cp ${../config/quickshell/greeter/shell.qml} $out/shell.qml
    cp ${../config/quickshell/auth/AlabasterAuth.qml} $out/AlabasterAuth.qml
  '';
  greeterSession = pkgs.writeShellScript "sharchy-greeter-session" ''
    export QT_QPA_PLATFORM=wayland
    export QT_SCALE_FACTOR=2
    export XKB_DEFAULT_OPTIONS=ctrl:nocaps
    export XCURSOR_THEME=macOS
    export XCURSOR_SIZE=24
    export XCURSOR_PATH=${pkgs.apple-cursor}/share/icons
    exec ${pkgs.dbus}/bin/dbus-run-session -- \
      ${pkgs.cage}/bin/cage -s -d -- \
      ${pkgs.quickshell}/bin/quickshell -p ${greeterConfig}
  '';
in
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
    settings.default_session = {
      command = greeterSession;
      user = "greeter";
    };
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  systemd.tmpfiles.rules = [
    "d /run/sharchy 0755 shardul users -"
    "f /run/sharchy/theme 0644 shardul users -"
  ];

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
  security.pam.services.sharchy-lock = { };
  security.pam.services.greetd.enableGnomeKeyring = true;
  systemd.services."getty@tty2".wantedBy = [ "getty.target" ];
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
    glib
    jq
    libnotify
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
