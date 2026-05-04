{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in {
      packages = forAll (pkgs:
        let
          dev = pkgs.buildEnv {
            name = "dev";
            paths = with pkgs; [
              fish
              git
              neovim
              tmux
              htop
              fd
              ripgrep
              bat
              fzf
              jq
              gh
              yazi
              zoxide
              atuin
              hyperfine
              jujutsu
              jjui
              nodejs
              uv
              lua-language-server
              vtsls
              tree-sitter
              direnv
            ];
          };
        in {
          inherit dev;
          default = dev;
        });
    };
}
