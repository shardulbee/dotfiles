{ pkgs, lib, config, ... }:
{
  home.stateVersion = lib.mkDefault "23.05";

  # Git configuration (for NixOS, macOS uses system git config)
  programs.git = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
  };

  # Common home files
  home.file = {
    ".hushlogin" = {
      text = "";
    };
  } // lib.optionalAttrs pkgs.stdenv.isLinux {
    "Documents/.keep" = {
      text = "";
    };
  };

  # Programs configuration
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.bat.enable = true;
}