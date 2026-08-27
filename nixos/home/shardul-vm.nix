{ config, pkgs, ... }:

let
  home = config.home.homeDirectory;
in
{
  home.username = "shardul";
  home.homeDirectory = "/home/shardul";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
  programs.zsh.enable = true;

  home.packages = with pkgs; [
    fd
    gh
    jjui
    ripgrep
    zoxide
  ];

  home.file.".zshrc".source = ../../zsh-config.zsh;
  xdg.configFile."mise/config.toml".source = ../../mise-config.toml;
  xdg.configFile."git/config".source = ../../git-config;
  xdg.configFile."git/ignore".source = ../../git-ignore;
  xdg.configFile."jj/config.toml".source = ../../jj-config.toml;
  xdg.configFile."jjui/config.lua".source = ../../jjui-config.lua;
  xdg.configFile."nvim/init.lua".source = ../../nvim-init.lua;
  xdg.configFile."nvim/colors/alabaster.lua".source = ../../nvim-colors-alabaster.lua;

  xdg.configFile."ghostty/config".text = builtins.replaceStrings
    [ "command = /usr/bin/zsh\n" ]
    [ "" ]
    (builtins.readFile ../../omarchy/ghostty/config);
  xdg.configFile."ghostty/themes/Alabaster Light".source = ../../ghostty-themes-alabaster-light;
  xdg.configFile."ghostty/themes/Alabaster Dark".source = ../../ghostty-themes-alabaster-dark;

  xdg.configFile."chromium-flags.conf".text = ''
    --password-store=gnome-libsecret
    --enable-features=TouchpadOverscrollHistoryNavigation
    --load-extension=${home}/.config/chromium/extensions/alt-click-new-tab
  '';
  xdg.configFile."chromium/extensions/alt-click-new-tab".source = ../../omarchy/chromium/extensions/alt-click-new-tab;

  xdg.configFile."i3/config".text = ''
    set $mod Mod4
    font pango:JetBrainsMono Nerd Font 11

    exec --no-startup-id xsetroot -solid "#ebe6da"
    exec --no-startup-id dunst
    exec --no-startup-id lxqt-policykit-agent

    gaps inner 5
    gaps outer 10
    default_border pixel 2
    default_floating_border pixel 2
    client.focused #007acc #007acc #f8f8f8 #007acc #007acc
    client.unfocused #d8d0c4 #d8d0c4 #272727 #d8d0c4 #d8d0c4

    bindsym $mod+Return exec ghostty
    bindsym $mod+space exec rofi -show drun
    bindsym $mod+b exec chromium
    bindsym Mod1+q kill
    bindsym Mod1+Tab workspace back_and_forth

    bindsym $mod+h focus left
    bindsym $mod+j focus down
    bindsym $mod+k focus up
    bindsym $mod+l focus right
    bindsym $mod+Shift+h move left
    bindsym $mod+Shift+j move down
    bindsym $mod+Shift+k move up
    bindsym $mod+Shift+l move right

    bindsym $mod+1 workspace number 1
    bindsym $mod+2 workspace number 2
    bindsym $mod+3 workspace number 3
    bindsym $mod+4 workspace number 4
    bindsym $mod+Shift+1 move container to workspace number 1
    bindsym $mod+Shift+2 move container to workspace number 2
    bindsym $mod+Shift+3 move container to workspace number 3
    bindsym $mod+Shift+4 move container to workspace number 4

    bar {
      status_command i3status
      colors {
        background #ebe6da
        statusline #272727
        focused_workspace #007acc #007acc #f8f8f8
        inactive_workspace #d8d0c4 #d8d0c4 #272727
      }
    }
  '';
}
