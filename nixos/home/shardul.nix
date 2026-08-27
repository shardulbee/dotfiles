{ config, pkgs, lib, ... }:

let
  home = config.home.homeDirectory;

  sharchyKey = pkgs.writeShellScript "sharchy-key" ''
    set -euo pipefail

    class="$(hyprctl activewindow -j 2>/dev/null | ${pkgs.jq}/bin/jq -r '.class // ""' || true)"
    is_terminal=false
    is_browser=false
    case "$class" in
      *[Gg]hostty*) is_terminal=true ;;
    esac
    case "$class" in
      *[Cc]hrom*|*chromium*|*firefox*|*Firefox*) is_browser=true ;;
    esac

    key() { ${pkgs.wtype}/bin/wtype "$@"; }

    case "''${1:-}" in
      copy)
        if $is_terminal; then key -M ctrl -k Insert -m ctrl; else key -M ctrl -k c -m ctrl; fi
        ;;
      paste)
        if $is_terminal; then key -M shift -k Insert -m shift; else key -M ctrl -k v -m ctrl; fi
        ;;
      select-all)
        if $is_terminal; then key -M ctrl -M shift -k a -m shift -m ctrl; else key -M ctrl -k a -m ctrl; fi
        ;;
      cut)
        if ! $is_terminal; then key -M ctrl -k x -m ctrl; fi
        ;;
      undo)
        if ! $is_terminal; then key -M ctrl -k z -m ctrl; fi
        ;;
      redo)
        if ! $is_terminal; then key -M ctrl -M shift -k z -m shift -m ctrl; fi
        ;;
      prev-word) key -M ctrl -k Left -m ctrl ;;
      next-word) key -M ctrl -k Right -m ctrl ;;
      select-prev-word) key -M ctrl -M shift -k Left -m shift -m ctrl ;;
      select-next-word) key -M ctrl -M shift -k Right -m shift -m ctrl ;;
      delete-prev-word)
        if $is_terminal; then key -M ctrl -k w -m ctrl; else key -M ctrl -k BackSpace -m ctrl; fi
        ;;
      delete-to-line-start)
        if $is_terminal; then
          key -M ctrl -k u -m ctrl
        else
          key -M shift -k Home -m shift
          key -k BackSpace
        fi
        ;;
      browser)
        shift
        if $is_browser; then key "$@"; fi
        ;;
      close)
        if $is_browser; then
          key -M ctrl -k w -m ctrl
        elif $is_terminal; then
          # Standard Hyprland supports `pass`; it forwards the chord to the app
          # instead of re-triggering this compositor binding.
          hyprctl dispatch pass ALT,W >/dev/null || key -M alt w -m alt
        else
          hyprctl dispatch killactive
        fi
        ;;
      *)
        echo "usage: sharchy-key <action>" >&2
        exit 2
        ;;
    esac
  '';

  sharchyGenerateBackgrounds = pkgs.writeShellScript "sharchy-generate-backgrounds" ''
    set -euo pipefail
    base="''${1:-$HOME/.local/share/sharchy/backgrounds}"
    mkdir -p "$base"

    ${pkgs.imagemagick}/bin/magick -size 3840x2160 xc:'#14120b' \
      \( -size 3840x2160 plasma:fractal -colorspace gray -blur 0x18 -auto-level -evaluate multiply 0.10 \) \
      -compose screen -composite \
      \( -size 3840x2160 xc:none -fill '#cd974b22' -draw 'rectangle 0,0 3840,2160' -blur 0x80 \) \
      -compose over -composite \
      \( -size 3840x2160 gradient:'#24221800-#09080588' \) \
      -compose over -composite \
      -quality 95 "$base/alabaster-dark.png"

    ${pkgs.imagemagick}/bin/magick -size 3840x2160 xc:'#ebe6da' \
      \( -size 3840x2160 plasma:fractal -colorspace gray -blur 0x20 -auto-level -evaluate multiply 0.06 \) \
      -compose multiply -composite \
      \( -size 3840x2160 radial-gradient:'#f7f1e6aa-#d8cdbb66' \) \
      -gravity center -compose over -composite \
      \( -size 3840x2160 gradient:'#fff7e855-#d1c2aa44' \) \
      -compose over -composite \
      -quality 95 "$base/alabaster-light.png"
  '';

  sharchyTheme = pkgs.writeShellScript "sharchy-theme" ''
    set -euo pipefail
    state_dir="$HOME/.local/state"
    bg_dir="$HOME/.local/share/sharchy/backgrounds"
    mkdir -p "$state_dir"

    if [ ! -f "$bg_dir/alabaster-dark.png" ] || [ ! -f "$bg_dir/alabaster-light.png" ]; then
      ${sharchyGenerateBackgrounds} "$bg_dir"
    fi

    mode="''${1:-toggle}"
    if [ "$mode" = auto ]; then
      hour=$(date +%H)
      if (( 10#$hour >= 7 && 10#$hour < 19 )); then mode=light; else mode=dark; fi
    elif [ "$mode" = toggle ]; then
      current=$(cat "$state_dir/sharchy-theme" 2>/dev/null || echo dark)
      if [ "$current" = light ]; then mode=dark; else mode=light; fi
    fi

    case "$mode" in
      light)
        echo light > "$state_dir/sharchy-theme"
        ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme prefer-light || true
        hyprctl keyword general:col.active_border 'rgba(007accee)' >/dev/null || true
        ${pkgs.awww}/bin/awww img "$bg_dir/alabaster-light.png" --transition-type none || true
        ;;
      dark)
        echo dark > "$state_dir/sharchy-theme"
        ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme prefer-dark || true
        hyprctl keyword general:col.active_border 'rgba(cd974bee)' >/dev/null || true
        ${pkgs.awww}/bin/awww img "$bg_dir/alabaster-dark.png" --transition-type none || true
        ;;
      *)
        echo "usage: sharchy-theme light|dark|toggle|auto" >&2
        exit 2
        ;;
    esac
  '';
in
{
  home.username = "shardul";
  home.homeDirectory = "/home/shardul";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
  programs.zsh.enable = true;

  # Personal CLI tools. The minimal desktop apps live in
  # nixos/modules/sharchy-desktop.nix.
  home.packages = with pkgs; [
    fd
    gh
    jjui
    ripgrep
    zoxide
  ];

  home.file.".zshrc".source = ../../zsh-config.zsh;
  home.file.".local/bin/sharchy-key".source = sharchyKey;
  home.file.".local/bin/sharchy-theme".source = sharchyTheme;
  home.file.".local/bin/sharchy-generate-backgrounds".source = sharchyGenerateBackgrounds;

  xdg.configFile."mise/config.toml".source = ../../mise-config.toml;
  xdg.configFile."git/config".source = ../../git-config;
  xdg.configFile."git/ignore".source = ../../git-ignore;
  xdg.configFile."jj/config.toml".source = ../../jj-config.toml;
  xdg.configFile."jjui/config.lua".source = ../../jjui-config.lua;
  xdg.configFile."nvim/init.lua".source = ../../nvim-init.lua;
  xdg.configFile."nvim/colors/alabaster.lua".source = ../../nvim-colors-alabaster.lua;

  xdg.configFile."ghostty/config".source = ../../omarchy/ghostty/config;
  xdg.configFile."ghostty/themes/Alabaster Light".source = ../../ghostty-themes-alabaster-light;
  xdg.configFile."ghostty/themes/Alabaster Dark".source = ../../ghostty-themes-alabaster-dark;

  xdg.configFile."chromium-flags.conf".text = ''
    --ozone-platform=wayland
    --ozone-platform-hint=wayland
    --password-store=gnome-libsecret
    --enable-features=TouchpadOverscrollHistoryNavigation
    --load-extension=${home}/.config/chromium/extensions/alt-click-new-tab
  '';
  xdg.configFile."chromium/extensions/alt-click-new-tab".source = ../../omarchy/chromium/extensions/alt-click-new-tab;
  xdg.configFile."xdg-terminals.list".source = ../../omarchy/xdg/xdg-terminals.list;

  xdg.configFile."hypr/hyprland.conf".text = ''
    monitor=,preferred,auto,1

    exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
    exec-once = awww-daemon
    exec-once = sharchy-theme auto

    input {
      kb_options = ctrl:nocaps
      natural_scroll = true
      repeat_rate = 60
      repeat_delay = 260
      touchpad {
        natural_scroll = true
      }
    }

    general {
      gaps_in = 5
      gaps_out = 10
      border_size = 2
      col.active_border = rgba(cd974bee)
      col.inactive_border = rgba(77777766)
    }

    decoration {
      rounding = 0
      shadow {
        enabled = false
      }
      blur {
        enabled = false
      }
    }

    animations { enabled = false }
    misc { vrr = 0 }

    bind = SUPER, RETURN, exec, ghostty
    bind = SUPER, SPACE, exec, chromium
    bind = ALT, Q, killactive
    bind = ALT, W, exec, sharchy-key close
    bind = ALT CTRL, T, exec, sharchy-theme toggle
    bind = ALT, TAB, workspace, previous

    bind = ALT, C, exec, sharchy-key copy
    bind = ALT, V, exec, sharchy-key paste
    bind = ALT, A, exec, sharchy-key select-all
    bind = SUPER, X, exec, sharchy-key cut
    bind = SUPER, Z, exec, sharchy-key undo
    bind = SUPER SHIFT, Z, exec, sharchy-key redo

    bind = SUPER, LEFT, exec, sharchy-key prev-word
    bind = SUPER, RIGHT, exec, sharchy-key next-word
    bind = SUPER SHIFT, LEFT, exec, sharchy-key select-prev-word
    bind = SUPER SHIFT, RIGHT, exec, sharchy-key select-next-word
    bind = SUPER, BACKSPACE, exec, sharchy-key delete-prev-word
    bind = ALT, BACKSPACE, exec, sharchy-key delete-to-line-start

    bind = SUPER, H, movefocus, l
    bind = SUPER, J, movefocus, d
    bind = SUPER, K, movefocus, u
    bind = SUPER, L, movefocus, r
    bind = SUPER SHIFT, H, swapwindow, l
    bind = SUPER SHIFT, J, swapwindow, d
    bind = SUPER SHIFT, K, swapwindow, u
    bind = SUPER SHIFT, L, swapwindow, r

    bind = ALT, L, exec, sharchy-key browser -M ctrl -k l -m ctrl
    bind = ALT, F, exec, sharchy-key browser -M ctrl -k f -m ctrl
    bind = ALT, T, exec, sharchy-key browser -M ctrl -k t -m ctrl
    bind = ALT SHIFT, T, exec, sharchy-key browser -M ctrl -M shift -k t -m shift -m ctrl
    bind = ALT, R, exec, sharchy-key browser -M ctrl -k r -m ctrl
    bind = ALT SHIFT, R, exec, sharchy-key browser -M ctrl -M shift -k r -m shift -m ctrl
    bind = ALT, BRACKETLEFT, exec, sharchy-key browser -M alt -k Left -m alt
    bind = ALT, BRACKETRIGHT, exec, sharchy-key browser -M alt -k Right -m alt
    bind = ALT SHIFT, BRACKETLEFT, exec, sharchy-key browser -M ctrl -M shift -k Tab -m shift -m ctrl
    bind = ALT SHIFT, BRACKETRIGHT, exec, sharchy-key browser -M ctrl -k Tab -m ctrl
    bind = ALT, EQUAL, exec, sharchy-key browser -M ctrl -k equal -m ctrl
    bind = ALT, MINUS, exec, sharchy-key browser -M ctrl -k minus -m ctrl
    bind = ALT, 0, exec, sharchy-key browser -M ctrl -k 0 -m ctrl
  '';

  systemd.user.services.sharchy-auto-theme = {
    Unit.Description = "Switch Sharchy theme based on local time";
    Service = {
      Type = "oneshot";
      ExecStart = "${sharchyTheme} auto";
    };
  };

  systemd.user.timers.sharchy-auto-theme = {
    Unit.Description = "Run Sharchy auto theme switcher";
    Timer = {
      OnBootSec = "2min";
      OnCalendar = [ "*-*-* 07:00:00" "*-*-* 19:00:00" ];
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
