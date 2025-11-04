{ pkgs, lib, ... }:

{
  imports = lib.optional (builtins.pathExists /etc/nixos/hardware-configuration.nix) /etc/nixos/hardware-configuration.nix;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  users.users.shardul = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.fish;
  };

  programs.fish.enable = true;
  security.sudo.wheelNeedsPassword = false;

  networking.networkmanager.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  programs.niri.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  };

  environment.systemPackages = with pkgs; [
    ghostty
    fuzzel
    wl-clipboard
    git
    jujutsu
    neovim
    ripgrep
    fd
    fzf
  ];

  system.activationScripts.niriConfig = ''
    mkdir -p /home/shardul/.config/niri
    cat > /home/shardul/.config/niri/config.kdl << 'EOF'
    input {
        keyboard {
            xkb {
                layout "us"
            }
        }
        touchpad {
            natural-scroll true
        }
    }

    layout {
        gaps 8
        border {
            width 2
            active-color "#d79921"
            inactive-color "#3c3836"
        }
    }

    spawn-at-startup "fuzzel"

    binds {
        Mod+Space { spawn "fuzzel"; }
        Mod+Return { spawn "ghostty"; }
        Mod+Q { close-window; }

        Mod+H { focus-column-left; }
        Mod+L { focus-column-right; }
        Mod+J { focus-window-down; }
        Mod+K { focus-window-up; }

        Mod+Shift+H { move-column-left; }
        Mod+Shift+L { move-column-right; }
        Mod+Shift+J { move-window-down; }
        Mod+Shift+K { move-window-up; }

        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }

        Mod+Shift+1 { move-column-to-workspace 1; }
        Mod+Shift+2 { move-column-to-workspace 2; }
        Mod+Shift+3 { move-column-to-workspace 3; }
        Mod+Shift+4 { move-column-to-workspace 4; }
        Mod+Shift+5 { move-column-to-workspace 5; }
        Mod+Shift+6 { move-column-to-workspace 6; }
        Mod+Shift+7 { move-column-to-workspace 7; }
        Mod+Shift+8 { move-column-to-workspace 8; }
        Mod+Shift+9 { move-column-to-workspace 9; }

        Mod+Comma { consume-window-into-column; }
        Mod+Period { expel-window-from-column; }

        Mod+F { fullscreen-window; }
        Mod+Shift+F { maximize-column; }
    }
    EOF
    chown shardul:users /home/shardul/.config/niri/config.kdl
  '';

  system.stateVersion = "24.05";
}
