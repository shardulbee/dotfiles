{ config, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/Documents/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
  grok-bot = pkgs.callPackage ../packages/grok-bot.nix { };
  zed = pkgs.writeShellScriptBin "zed" ''
    exec ${pkgs.zed-editor}/bin/zeditor "$@"
  '';
in
{
  home.username = "shardul";
  home.homeDirectory = "/home/shardul";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    atuin
    btop
    clang_22
    codex
    direnv
    fd
    fish
    fzf
    gh
    go_1_27
    grok-bot
    hyperfine
    jjui
    jq
    jujutsu
    neovim
    nodejs_26
    rclone
    ripgrep
    tmux
    trash-cli
    tree-sitter
    usage
    uv
    yazi
    yt-dlp
    zed
    zed-editor
    zoxide
    zsh-autosuggestions
  ];

  home.sessionVariables.NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  home.sessionPath = [ "$HOME/.npm-global/bin" "$HOME/.local/bin" ];

  home.pointerCursor = {
    enable = true;
    package = pkgs.apple-cursor;
    name = "macOS";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  home.file.".zshrc".source = link "zsh-config.zsh";
  home.file.".local/bin/sharchy-helium".source = ../scripts/sharchy-helium;
  home.file.".local/bin/sharchy-helium-defaults".source = ../scripts/sharchy-helium-defaults;
  home.file.".local/bin/sharchy-screenshot".source = ../scripts/sharchy-screenshot;
  home.file.".local/bin/sharchy-theme".source = ../scripts/sharchy-theme;
  home.file.".local/bin/sharchy-keybindings".source = ../scripts/sharchy-keybindings;
  home.file.".local/bin/sharchy-quake".source = ../scripts/sharchy-quake;
  home.file.".local/bin/sharchy-rebuild".source = ../scripts/sharchy-rebuild;
  home.file.".local/bin/sharchy-workspace".source = ../scripts/sharchy-workspace;

  systemd.user.services.sharchy-bar = {
    Unit = {
      Description = "Minimal Sharchy desktop bar";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.quickshell}/bin/quickshell -p /home/shardul/.config/quickshell/sharchy";
      Restart = "on-failure";
      RestartSec = 1;
      Environment = "QS_NO_RELOAD_POPUP=1";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.hyprpolkitagent = {
    Unit = {
      Description = "Hyprland authentication agent";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      ConditionEnvironment = [ "WAYLAND_DISPLAY" ];
    };
    Service = {
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.mako = {
    Unit = {
      Description = "Mako notification daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      X-Restart-Triggers = [ "${config.xdg.configFile."mako/config".source}" ];
    };
    Service = {
      ExecStart = "${pkgs.mako}/bin/mako";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.sharchy-helium-defaults = {
    Unit = {
      Description = "Enable Helium extension downloads";
      Before = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "/home/shardul/.local/bin/sharchy-helium-defaults";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.sharchy-theme-scheduled = {
    Unit.Description = "Apply the scheduled Sharchy theme";
    Service = {
      Type = "oneshot";
      ExecStart = "/home/shardul/.local/bin/sharchy-theme scheduled";
    };
  };
  systemd.user.timers.sharchy-theme-scheduled = {
    Unit.Description = "Switch themes at 07:00 and 19:00";
    Timer = {
      OnCalendar = "*-*-* 07,19:00:00";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  xdg.configFile."git/config".source = link "git-config";
  xdg.configFile."git/ignore".source = link "git-ignore";
  xdg.configFile."jj/config.toml".source = link "jj-config.toml";
  xdg.configFile."jjui/config.lua".source = link "jjui-config.lua";
  xdg.configFile."nvim/init.lua".source = link "nvim-init.lua";
  xdg.configFile."nvim/colors/alabaster.lua".source = link "nvim-colors-alabaster.lua";
  xdg.configFile."zed/settings.json".source = link "zed-settings.json";
  xdg.configFile."zed/keymap.json".source = link "zed-keymap.json";
  xdg.configFile."zed/tasks.json".source = link "zed-tasks.json";
  xdg.configFile."zed/themes/soft.json".source = link "zed-theme-soft.json";
  xdg.configFile."ghostty/config".source = ../config/ghostty/config;
  xdg.configFile."ghostty/themes/Alabaster Light".source = ../../ghostty-themes-alabaster-light;
  xdg.configFile."ghostty/themes/Alabaster Dark".source = ../../ghostty-themes-alabaster-dark;
  xdg.configFile."helium-browser-flags.conf".source = ../config/helium-browser-flags.conf;
  xdg.desktopEntries.helium = {
    name = "Helium";
    genericName = "Web Browser";
    exec = "/home/shardul/.local/bin/sharchy-helium %U";
    icon = "helium";
    terminal = false;
    categories = [ "Network" "WebBrowser" ];
    mimeType = [ "text/html" "x-scheme-handler/http" "x-scheme-handler/https" ];
  };
  xdg.configFile."chromium/extensions/alt-click-new-tab".source = ../config/browser/extensions/alt-click-new-tab;
  xdg.configFile."hypr/hyprland.conf".source = ../config/hypr/sharchy.conf;
  xdg.configFile."hypr/hyprlock.conf".source = ../config/hyprlock/config;
  xdg.configFile."mako/config".source = ../config/mako/config;
  xdg.configFile."quickshell/sharchy/shell.qml".source = ../config/quickshell/sharchy/shell.qml;
}
