{ fetchFromGitHub, buildGoModule }:

buildGoModule {
  pname = "natterwire-tui";
  version = "0-unstable-f61a2f0";

  src = fetchFromGitHub {
    owner = "shardulbee";
    repo = "natterwire";
    rev = "f61a2f0749a9229a54cb2b2e62b7a43b9e70063c";
    hash = "sha256-s9BMHWqiczAIJUOk8FDudxrQt3IRrMipquntPcqMeOc=";
    # Supply NIX_GITHUB_PRIVATE_USERNAME/PASSWORD to the builder, never in Nix.
    private = true;
  };
  modRoot = "tui";
  subPackages = [ "." ];
  vendorHash = "sha256-d7E6KLG1EpEoXLlwh29g3YpOmsNQ6RaN8Cu0Q0NRNzw=";
  env.CGO_ENABLED = 0;

  postInstall = ''
    mv "$out/bin/tui" "$out/bin/natterwire-tui"
  '';

  meta = {
    description = "Terminal client for Natterwire";
    homepage = "https://github.com/shardulbee/natterwire";
    mainProgram = "natterwire-tui";
  };
}
