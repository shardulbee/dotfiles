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
  home.file.".local/bin/sharchy-key".source = link "nixos/scripts/sharchy-key";
  home.file.".local/bin/sharchy-theme".source = link "nixos/scripts/sharchy-theme";
  home.file.".local/bin/sharchy-keybindings".source = link "nixos/scripts/sharchy-keybindings";

  xdg.configFile."git/config".source = link "git-config";
  xdg.configFile."git/ignore".source = link "git-ignore";
  xdg.configFile."jj/config.toml".source = link "jj-config.toml";
  xdg.configFile."jjui/config.lua".source = link "jjui-config.lua";
  xdg.configFile."nvim/init.lua".source = link "nvim-init.lua";
  xdg.configFile."nvim/colors/alabaster.lua".source = link "nvim-colors-alabaster.lua";
  xdg.configFile."ghostty/config".source = link "omarchy/ghostty/config";
  xdg.configFile."ghostty/themes/Alabaster Light".source = link "ghostty-themes-alabaster-light";
  xdg.configFile."ghostty/themes/Alabaster Dark".source = link "ghostty-themes-alabaster-dark";
  xdg.configFile."helium-browser-flags.conf".source = link "nixos/config/helium-browser-flags.conf";
  xdg.configFile."chromium/extensions/alt-click-new-tab".source = link "omarchy/chromium/extensions/alt-click-new-tab";
  xdg.configFile."niri/config.kdl".source = link "nixos/config/niri/sharchy.kdl";
  xdg.configFile."waybar/config".source = link "nixos/config/waybar/sharchy.json";
  xdg.configFile."waybar/style.css".source = link "nixos/config/waybar/style.css";
  xdg.configFile."mako/config".source = link "nixos/config/mako/config";
}
