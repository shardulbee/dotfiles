{ lib, fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage {
  pname = "uberstat";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "shardulbee";
    repo = "uberstat";
    rev = "19ab145f97f95f99b113fa7fea73f16d2dd15121";
    hash = "sha256-+2xlRPXap8sqQMUhfRcFgvqz6JYLJAGHLo8I6Klm8vg=";
  };
  cargoHash = "sha256-j6gp2e3leC9RhSl7jn+Ywaw4aGTr+1q+peYWqGy6VIM=";

  meta = {
    description = "Fast, Jujutsu-first workspace status dashboard";
    homepage = "https://github.com/shardulbee/uberstat";
    license = lib.licenses.mit;
    mainProgram = "uberstat";
  };
}
