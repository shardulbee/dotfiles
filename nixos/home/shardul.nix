{ config, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/Documents/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
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
    zoxide
    zsh-autosuggestions
  ];

  home.sessionVariables.NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  home.sessionPath = [ "$HOME/.npm-global/bin" "$HOME/.local/bin" ];

  home.file.".zshrc".source = link "zsh-config.zsh";
  home.file.".local/bin/sharchy-helium".source = link "nixos/scripts/sharchy-helium";
  home.file.".local/bin/sharchy-helium-defaults".source = link "nixos/scripts/sharchy-helium-defaults";
  home.file.".local/bin/sharchy-screenshot".source = link "nixos/scripts/sharchy-screenshot";
  home.file.".local/bin/sharchy-theme".source = link "nixos/scripts/sharchy-theme";
  home.file.".local/bin/sharchy-keybindings".source = link "nixos/scripts/sharchy-keybindings";
  home.file.".local/bin/sharchy-quake".source = link "nixos/scripts/sharchy-quake";

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

  systemd.user.services.mako = {
    Unit = {
      Description = "Mako notification daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
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
  xdg.configFile."ghostty/config".source = link "nixos/config/ghostty/config";
  xdg.configFile."ghostty/themes/Alabaster Light".source = link "ghostty-themes-alabaster-light";
  xdg.configFile."ghostty/themes/Alabaster Dark".source = link "ghostty-themes-alabaster-dark";
  xdg.configFile."helium-browser-flags.conf".source = link "nixos/config/helium-browser-flags.conf";
  xdg.desktopEntries.helium = {
    name = "Helium";
    genericName = "Web Browser";
    exec = "/home/shardul/.local/bin/sharchy-helium %U";
    icon = "helium";
    terminal = false;
    categories = [ "Network" "WebBrowser" ];
    mimeType = [ "text/html" "x-scheme-handler/http" "x-scheme-handler/https" ];
  };
  xdg.configFile."chromium/extensions/alt-click-new-tab".source = link "nixos/config/browser/extensions/alt-click-new-tab";
  xdg.configFile."hypr/hyprland.conf".source = link "nixos/config/hypr/sharchy.conf";
  xdg.configFile."hypr/hyprlock.conf".source = link "nixos/config/hyprlock/config";
  xdg.configFile."mako/config".source = link "nixos/config/mako/config";
  xdg.configFile."quickshell/sharchy/shell.qml".source = link "nixos/config/quickshell/sharchy/shell.qml";
}
