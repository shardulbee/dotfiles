{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (sys: f nixpkgs.legacyPackages.${sys});
    in {
      packages = forAll (pkgs: {
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
            nodejs
            bun
            uv
            lua-language-server
            tree-sitter
            direnv
          ];
        };
      });
    };
}
