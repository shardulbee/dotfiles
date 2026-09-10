{ buildNpmPackage, fetchFromGitHub }:

buildNpmPackage {
  pname = "obsidian-clipper";
  version = "1.7.1-managed";

  src = fetchFromGitHub {
    owner = "shardulbee";
    repo = "obsidian-clipper";
    rev = "39b8743f639f0c719a4f930780c58e9d77031a91";
    hash = "sha256-H39hATM9qVQFboIVictryTZ0xi43W4sCZv9JzXaMH6E=";
  };

  patches = [ ./obsidian-clipper-interpreter.patch ];

  npmDepsHash = "sha256-zgKeIchtjHiZE+m/+ACrsYriV5uPx9P85PuPMqhbIHc=";
  npmFlags = [ "--legacy-peer-deps" ];
  npmBuildScript = "build:chrome";

  installPhase = ''
    runHook preInstall
    cp -r dist "$out"
    runHook postInstall
  '';
}
