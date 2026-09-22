{ lib, options, pkgs, ... }:

let
  alabasterNvim = pkgs.vimUtils.buildVimPlugin {
    pname = "alabaster-nvim";
    version = "1";
    src = pkgs.runCommand "alabaster-nvim-source" { } ''
      mkdir -p "$out/colors"
      cp ${./nvim-alabaster.lua} "$out/colors/alabaster.lua"
    '';
  };
in
{
  home.packages = with pkgs; [ fd jq ripgrep ];
  home.sessionPath = [ "$HOME/.local/bin" ];

  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    flags = [ "--disable-up-arrow" ];
  };
  programs.btop = {
    enable = true;
    settings = {
      proc_aggregate = true;
      proc_tree_auto_collapse = 1;
    };
  };
  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
  };
  programs.fish = {
    enable = true;
    functions.fish_greeting = "";
    functions.fish_vcs_prompt = "";
    interactiveShellInit = ''
      fish_add_path -gm "$HOME/.local/bin" "$HOME/bin"
    '';
    shellInitLast = ''
      test -f "$HOME/.config/fish/local.fish"; and source "$HOME/.config/fish/local.fish"
    '';
  };
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  } // lib.optionalAttrs (lib.hasAttrByPath [ "programs" "fzf" "historyWidget" ] options) {
    historyWidget.command = "";
  };
  programs.gh = {
    enable = true;
    gitCredentialHelper = {
      enable = true;
      hosts = [ "https://github.com" "https://gist.github.com" ];
    };
  };
  programs.git = {
    enable = true;
    ignores = [ ".DS_Store" ".git/" ".direnv/" ];
    settings.init.defaultBranch = "main";
  };
  programs.jujutsu = {
    enable = true;
    ediff = false;
    settings = {
      ui.default-command = "log";
      revset-aliases."closest_bookmark(to)" = "heads(::to & bookmarks())";
      aliases.tug = [ "bookmark" "move" "--from" "closest_bookmark(@-)" "--to" "@-" ];
      template-aliases."format_timestamp(timestamp)" = "timestamp.ago()";
    };
  };
  programs.jjui = {
    enable = true;
    configLua = ''
      ---@diagnostic disable: undefined-global, lowercase-global
      function setup(config)
          config.ui = config.ui or {}
          config.ui.set_window_title = false
      end
    '';
  };
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [
      alabasterNvim
      fzf-lua
      snacks-nvim
      vim-surround
      (nvim-treesitter.withPlugins (p: with p; [
        bash html javascript json lua markdown nix python tsx typescript vim vimdoc yaml
      ]))
    ];
    initLua = builtins.readFile ./nvim.lua;
  };
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    escapeTime = 0;
    focusEvents = true;
    historyLimit = 100000;
    keyMode = "vi";
    mouse = true;
    terminal = "tmux-256color";
    extraConfig = ''
      bind -r h select-pane -L
      bind -r j select-pane -D
      bind -r k select-pane -U
      bind -r l select-pane -R
      bind -r H swap-pane -t '{left-of}'
      bind -r J swap-pane -t '{down-of}'
      bind -r K swap-pane -t '{up-of}'
      bind -r L swap-pane -t '{right-of}'
      bind v split-window -h -c '#{pane_current_path}'
      bind c new-window -c '#{pane_current_path}'
      bind Escape copy-mode -u
      bind x kill-pane
      bind R source-file ~/.config/tmux/tmux.conf \; display-message 'tmux config reloaded'
      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      set -g renumber-windows on
      setw -g automatic-rename on
      setw -g automatic-rename-format '#{b:pane_current_path}'
      set -g set-clipboard on
      set -g extended-keys on
      set -g extended-keys-format csi-u
      set -g status-position bottom
      set -g status-interval 5
      set -g status-style 'bg=default,fg=default'
      set -g status-left ' #S '
      set -g status-right '#[fg=colour8]%H:%M #[default]'
      set -g window-status-separator ""
      set -g window-status-format '#[fg=colour8] #I:#W '
      set -g window-status-current-format '#[fg=colour4,bold] #I:#W #[default]'
      set -g pane-border-style 'fg=colour8'
      set -g pane-active-border-style 'fg=colour4'
      set -g message-style 'fg=colour0,bg=colour4'
      set -g mode-style 'fg=colour0,bg=colour4'
    '';
  };
  programs.yazi.enable = true;
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };
}
