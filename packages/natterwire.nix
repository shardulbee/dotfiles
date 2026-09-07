{ fetchFromGitHub, buildGoModule }:

buildGoModule {
  pname = "natterwire-tui";
  version = "0-unstable-e7f1a31";

  src = fetchFromGitHub {
    owner = "shardulbee";
    repo = "natterwire";
    rev = "e7f1a3136dbbf26c92ea9a908e494fb124fb3ac4";
    hash = "sha256-Pe39cavfhdcpdFRtqgKdpzz5e2e4jmbdCqXlSWTu9us=";
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
