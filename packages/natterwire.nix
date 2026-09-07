{ fetchFromGitHub, buildGoModule }:

buildGoModule {
  pname = "natterwire-tui";
  version = "0-unstable-aaba707";

  src = fetchFromGitHub {
    owner = "shardulbee";
    repo = "natterwire";
    rev = "aaba707e285cb2ea31d2c1cfba0291ebfcc5f7a6";
    hash = "sha256-zQ56sPXxxATHRadEUKnCVvw5uDfG9LctYRS5vDAr3I0=";
  };
  modRoot = "tui";
  subPackages = [ "." ];
  vendorHash = "sha256-YE9fNQcDJVJk2lNWL3OetqaW82Hgaj8050cNugaqpHU=";
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
