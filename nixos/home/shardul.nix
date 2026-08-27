{ config, pkgs, ... }:

let
  home = config.home.homeDirectory;

  sharchyKey = pkgs.writeShellScript "sharchy-key" ''
    set -euo pipefail

    app_id="$(${pkgs.niri}/bin/niri msg --json focused-window 2>/dev/null | ${pkgs.jq}/bin/jq -r '.app_id // ""' || true)"
    app_id="''${app_id,,}"
    is_terminal=false
    is_browser=false
    case "$app_id" in
      *ghostty*) is_terminal=true ;;
      *chrom*|*firefox*) is_browser=true ;;
    esac

    send_key() {
      local mods="$1" key="$2" mod
      local -a args=()
      for mod in $mods; do args+=(-M "$mod"); done
      args+=(-k "$key")
      for mod in $mods; do args+=(-m "$mod"); done
      ${pkgs.wtype}/bin/wtype "''${args[@]}"
    }

    case "''${1:-}" in
      copy)
        if $is_terminal; then send_key ctrl Insert; else send_key ctrl c; fi
        ;;
      paste)
        if $is_terminal; then send_key shift Insert; else send_key ctrl v; fi
        ;;
      select-all)
        if $is_terminal; then send_key "ctrl shift" a; else send_key ctrl a; fi
        ;;
      cut)
        $is_terminal || send_key ctrl x
        ;;
      undo)
        $is_terminal || send_key ctrl z
        ;;
      redo)
        $is_terminal || send_key "ctrl shift" z
        ;;
      prev-word) send_key ctrl Left ;;
      next-word) send_key ctrl Right ;;
      select-prev-word) send_key "ctrl shift" Left ;;
      select-next-word) send_key "ctrl shift" Right ;;
      delete-prev-word)
        if $is_terminal; then send_key ctrl w; else send_key ctrl BackSpace; fi
        ;;
      delete-to-line-start)
        if $is_terminal; then
          send_key ctrl u
        else
          send_key shift Home
          sleep 0.05
          send_key "" BackSpace
        fi
        ;;
      browser)
        if $is_browser; then
          send_key "$2" "$3"
        else
          send_key "$4" "$5"
        fi
        ;;
      close)
        if $is_browser; then
          send_key ctrl w
        elif $is_terminal; then
          send_key alt w
        else
          ${pkgs.niri}/bin/niri msg action close-window
        fi
        ;;
      *)
        echo "usage: sharchy-key <action>" >&2
        exit 2
        ;;
    esac
  '';

  sharchyTheme = pkgs.writeShellScript "sharchy-theme" ''
    set -euo pipefail
    state="$HOME/.local/state/sharchy-theme"
    mkdir -p "$(dirname "$state")"
    mode="''${1:-toggle}"
    if [ "$mode" = toggle ]; then
      current="$(cat "$state" 2>/dev/null || echo light)"
      if [ "$current" = light ]; then mode=dark; else mode=light; fi
    fi
    case "$mode" in
      light)
        echo light > "$state"
        ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme prefer-light
        ;;
      dark)
        echo dark > "$state"
        ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme prefer-dark
        ;;
      *) exit 2 ;;
    esac
    ${pkgs.libnotify}/bin/notify-send "Alabaster $mode"
  '';

  sharchyKeybindings = pkgs.writeShellScript "sharchy-keybindings" ''
    ${pkgs.coreutils}/bin/cat <<'EOF' | ${pkgs.fuzzel}/bin/fuzzel --dmenu --prompt='Keybindings > ' --width=66 --lines=22
Super + Space                 App launcher
Super + Return                Terminal
Super + Shift + B             Browser
Super + Alt + K               This shortcut reference
Super + Shift + /             Niri hotkey overlay
Super + Escape                Lock screen
Super + H/J/K/L               Focus left/down/up/right
Super + Shift + H/J/K/L       Move window left/down/up/right
Super + 1…9                   Focus workspace
Super + Shift + 1…9           Move window to workspace
Super + R                     Cycle column width
Super + F                     Maximize column
Super + Shift + F             Fullscreen window
Alt + Tab                     Previous workspace
Alt + Q                       Close window
Alt + C/V/A                   Copy/paste/select all
Super + X/Z/Shift+Z           Cut/undo/redo
Super + Left/Right            Move by word
Alt + L/T/W/R/F               Browser address/tab/close/reload/find
Alt + Ctrl + T                Toggle light/dark theme
Print / Ctrl+Print/Alt+Print  Screenshot region/screen/window
Brightness and volume keys    Adjust display/audio
EOF
  '';
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
  home.file.".local/bin/sharchy-key".source = sharchyKey;
  home.file.".local/bin/sharchy-theme".source = sharchyTheme;
  home.file.".local/bin/sharchy-keybindings".source = sharchyKeybindings;
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
    --ozone-platform=wayland
    --ozone-platform-hint=wayland
    --password-store=basic
    --enable-features=TouchpadOverscrollHistoryNavigation
    --load-extension=${home}/.config/chromium/extensions/alt-click-new-tab
  '';
  xdg.configFile."chromium/extensions/alt-click-new-tab".source = ../../omarchy/chromium/extensions/alt-click-new-tab;

  xdg.configFile."niri/config.kdl".text = ''
    input {
      keyboard {
        xkb { options "ctrl:nocaps"; }
        repeat-delay 260
        repeat-rate 60
      }
      touchpad {
        tap
        natural-scroll
      }
      mouse { }
      focus-follows-mouse max-scroll-amount="0%"
    }

    output "eDP-1" {
      scale 2
    }

    layout {
      gaps 10
      center-focused-column "never"
      preset-column-widths {
        proportion 0.33333
        proportion 0.5
        proportion 0.66667
      }
      default-column-width { proportion 0.5; }
      focus-ring {
        width 2
        active-color "#007acc"
        inactive-color "#d8d0c4"
      }
      border { off; }
      shadow { off; }
    }

    prefer-no-csd
    spawn-at-startup "swaybg" "-c" "#ebe6da"
    spawn-at-startup "waybar"
    spawn-at-startup "mako"
    spawn-at-startup "lxqt-policykit-agent"
    spawn-at-startup "swayidle" "-w" "timeout" "300" "swaylock -f -c 272727" "timeout" "600" "niri msg action power-off-monitors" "resume" "niri msg action power-on-monitors" "before-sleep" "swaylock -f -c 272727"

    environment {
      NIXOS_OZONE_WL "1"
      MOZ_ENABLE_WAYLAND "1"
    }

    cursor {
      xcursor-theme "Adwaita"
      xcursor-size 24
      hide-when-typing
    }

    xwayland-satellite {
      path "xwayland-satellite"
    }

    hotkey-overlay {
      skip-at-startup
    }

    binds {
      Super+Return repeat=false { spawn "ghostty"; }
      Super+Space repeat=false { spawn "fuzzel"; }
      Super+Shift+B repeat=false { spawn "chromium"; }
      Super+Shift+Slash repeat=false { show-hotkey-overlay; }
      Super+Alt+K repeat=false { spawn "${sharchyKeybindings}"; }
      Super+O repeat=false { toggle-overview; }
      Super+Escape repeat=false { spawn "swaylock" "-f" "-c" "272727"; }
      Alt+Q repeat=false { close-window; }
      Alt+Tab repeat=false { focus-workspace-previous; }

      Alt+C repeat=false { spawn "${sharchyKey}" "copy"; }
      Alt+V repeat=false { spawn "${sharchyKey}" "paste"; }
      Alt+A repeat=false { spawn "${sharchyKey}" "select-all"; }
      Super+A repeat=false { spawn "${sharchyKey}" "select-all"; }
      Super+X repeat=false { spawn "${sharchyKey}" "cut"; }
      Super+Z repeat=false { spawn "${sharchyKey}" "undo"; }
      Super+Shift+Z repeat=false { spawn "${sharchyKey}" "redo"; }
      Super+Left { spawn "${sharchyKey}" "prev-word"; }
      Super+Right { spawn "${sharchyKey}" "next-word"; }
      Super+Shift+Left { spawn "${sharchyKey}" "select-prev-word"; }
      Super+Shift+Right { spawn "${sharchyKey}" "select-next-word"; }
      Super+BackSpace { spawn "${sharchyKey}" "delete-prev-word"; }
      Alt+BackSpace { spawn "${sharchyKey}" "delete-to-line-start"; }

      Alt+L repeat=false { spawn "${sharchyKey}" "browser" "ctrl" "l" "alt" "l"; }
      Alt+Comma repeat=false { spawn "${sharchyKey}" "browser" "ctrl" "comma" "alt" "comma"; }
      Alt+F repeat=false { spawn "${sharchyKey}" "browser" "ctrl" "f" "alt" "f"; }
      Alt+T repeat=false { spawn "${sharchyKey}" "browser" "ctrl" "t" "alt" "t"; }
      Alt+W repeat=false { spawn "${sharchyKey}" "close"; }
      Alt+Ctrl+T repeat=false { spawn "${sharchyTheme}" "toggle"; }
      Alt+Shift+BracketLeft repeat=false { spawn "${sharchyKey}" "browser" "ctrl shift" "Tab" "alt shift" "bracketleft"; }
      Alt+Shift+BracketRight repeat=false { spawn "${sharchyKey}" "browser" "ctrl" "Tab" "alt shift" "bracketright"; }
      Alt+BracketLeft repeat=false { spawn "${sharchyKey}" "browser" "alt" "Left" "alt" "bracketleft"; }
      Alt+BracketRight repeat=false { spawn "${sharchyKey}" "browser" "alt" "Right" "alt" "bracketright"; }
      Alt+R repeat=false { spawn "${sharchyKey}" "browser" "ctrl" "r" "alt" "r"; }
      Alt+Shift+R repeat=false { spawn "${sharchyKey}" "browser" "ctrl shift" "r" "alt shift" "r"; }
      Alt+Shift+T repeat=false { spawn "${sharchyKey}" "browser" "ctrl shift" "t" "alt shift" "t"; }
      Alt+1 repeat=false { spawn "${sharchyKey}" "browser" "ctrl" "1" "alt" "1"; }
      Alt+2 repeat=false { spawn "${sharchyKey}" "browser" "ctrl" "2" "alt" "2"; }
      Alt+3 repeat=false { spawn "${sharchyKey}" "browser" "ctrl" "3" "alt" "3"; }
      Alt+4 repeat=false { spawn "${sharchyKey}" "browser" "ctrl" "4" "alt" "4"; }
      Alt+5 repeat=false { spawn "${sharchyKey}" "browser" "ctrl" "5" "alt" "5"; }
      Alt+6 repeat=false { spawn "${sharchyKey}" "browser" "ctrl" "6" "alt" "6"; }
      Alt+7 repeat=false { spawn "${sharchyKey}" "browser" "ctrl" "7" "alt" "7"; }
      Alt+8 repeat=false { spawn "${sharchyKey}" "browser" "ctrl" "8" "alt" "8"; }
      Alt+9 repeat=false { spawn "${sharchyKey}" "browser" "ctrl" "9" "alt" "9"; }
      Alt+N repeat=false { spawn "${sharchyKey}" "browser" "ctrl" "n" "alt" "n"; }
      Alt+Shift+N repeat=false { spawn "${sharchyKey}" "browser" "ctrl shift" "n" "alt shift" "n"; }
      Alt+D repeat=false { spawn "${sharchyKey}" "browser" "ctrl" "d" "alt" "d"; }
      Alt+P repeat=false { spawn "${sharchyKey}" "browser" "ctrl" "p" "alt" "p"; }
      Alt+S repeat=false { spawn "${sharchyKey}" "browser" "ctrl" "s" "alt" "s"; }
      Alt+O repeat=false { spawn "${sharchyKey}" "browser" "ctrl" "o" "alt" "o"; }
      Alt+J repeat=false { spawn "${sharchyKey}" "browser" "ctrl" "j" "alt" "j"; }
      Alt+Y repeat=false { spawn "${sharchyKey}" "browser" "ctrl" "h" "alt" "y"; }
      Alt+Equal repeat=false { spawn "${sharchyKey}" "browser" "ctrl" "equal" "alt" "equal"; }
      Alt+Minus repeat=false { spawn "${sharchyKey}" "browser" "ctrl" "minus" "alt" "minus"; }
      Alt+0 repeat=false { spawn "${sharchyKey}" "browser" "ctrl" "0" "alt" "0"; }

      Super+H { focus-column-left; }
      Super+J { focus-window-down; }
      Super+K { focus-window-up; }
      Super+L { focus-column-right; }
      Super+Shift+H { move-column-left; }
      Super+Shift+J { move-window-down; }
      Super+Shift+K { move-window-up; }
      Super+Shift+L { move-column-right; }

      Super+1 { focus-workspace 1; }
      Super+2 { focus-workspace 2; }
      Super+3 { focus-workspace 3; }
      Super+4 { focus-workspace 4; }
      Super+5 { focus-workspace 5; }
      Super+6 { focus-workspace 6; }
      Super+7 { focus-workspace 7; }
      Super+8 { focus-workspace 8; }
      Super+9 { focus-workspace 9; }
      Super+Shift+1 { move-column-to-workspace 1; }
      Super+Shift+2 { move-column-to-workspace 2; }
      Super+Shift+3 { move-column-to-workspace 3; }
      Super+Shift+4 { move-column-to-workspace 4; }
      Super+Shift+5 { move-column-to-workspace 5; }
      Super+Shift+6 { move-column-to-workspace 6; }
      Super+Shift+7 { move-column-to-workspace 7; }
      Super+Shift+8 { move-column-to-workspace 8; }
      Super+Shift+9 { move-column-to-workspace 9; }

      Super+R { switch-preset-column-width; }
      Super+F { maximize-column; }
      Super+Shift+F { fullscreen-window; }

      XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
      XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
      XF86AudioMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
      XF86AudioMicMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }
      XF86MonBrightnessUp allow-when-locked=true { spawn "brightnessctl" "set" "+5%"; }
      XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "set" "5%-"; }

      Print repeat=false { screenshot; }
      Ctrl+Print repeat=false { screenshot-screen; }
      Alt+Print repeat=false { screenshot-window; }
    }
  '';

  xdg.configFile."waybar/config".text = builtins.toJSON {
    layer = "top";
    position = "bottom";
    height = 28;
    modules-left = [ "niri/workspaces" ];
    modules-right = [ "network" "battery" "cpu" "memory" "disk" "clock" ];
    "niri/workspaces" = { format = "{index}"; };
    network = {
      format-ethernet = "{ipaddr}";
      format-wifi = "{essid} {signalStrength}%";
      format-disconnected = "offline";
    };
    battery = {
      format = "bat {capacity}%";
      format-charging = "bat {capacity}%+";
      warning = 20;
      critical = 10;
    };
    cpu = { format = "cpu {usage}%"; };
    memory = { format = "mem {percentage}%"; };
    disk = { format = "disk {percentage_used}%"; };
    clock = { format = "{:%Y-%m-%d %H:%M}"; };
  };

  xdg.configFile."waybar/style.css".text = ''
    * {
      border: none;
      border-radius: 0;
      font-family: "JetBrainsMono Nerd Font";
      font-size: 13px;
      min-height: 0;
    }
    window#waybar {
      background: #ebe6da;
      color: #272727;
    }
    #workspaces button {
      padding: 0 10px;
      color: #272727;
    }
    #workspaces button.focused,
    #workspaces button.active {
      background: #007acc;
      color: #f8f8f8;
    }
    #network, #battery, #cpu, #memory, #disk, #clock {
      padding: 0 9px;
    }
  '';

  xdg.configFile."mako/config".text = ''
    font=JetBrainsMono Nerd Font 11
    background-color=#f8f8f8
    text-color=#272727
    border-color=#007acc
    border-size=2
    border-radius=0
  '';
}
