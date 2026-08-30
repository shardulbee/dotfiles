{ lib, fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage {
  pname = "uberstat";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "shardulbee";
    repo = "uberstat";
    rev = "4f9cdcb492c0bc17e277bd4f5aea2cd94135d958";
    hash = "sha256-hRCPKxBgWR6GOm4MfYmE7ubzsrgvmaoYFqGFYj/yRFk=";
  };
  cargoHash = "sha256-H4QT6f/6xnVpcqdn10aXfMXex/35+/WFXZCs1YbigOE=";

  meta = {
    description = "Fast, Jujutsu-first workspace status dashboard";
    homepage = "https://github.com/shardulbee/uberstat";
    license = lib.licenses.mit;
    mainProgram = "uberstat";
  };
}
