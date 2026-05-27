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
              fd
              ripgrep
              fzf
              jq
              gh
              zoxide
              atuin
              jujutsu
              jjui
              nodejs
              uv
              tree-sitter
              direnv
              nil
              nixfmt
            ];
          };
        in {
          inherit dev;
          default = dev;
        });
    };
}
