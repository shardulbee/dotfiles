{ buildGoModule, makeWrapper, git, cacert }:

buildGoModule {
  pname = "github-sync";
  version = "0.1.0";
  src = ./github-sync;
  vendorHash = null;
  nativeBuildInputs = [ makeWrapper ];
  nativeCheckInputs = [ git ];
  postInstall = ''
    wrapProgram "$out/bin/github-sync" \
      --prefix PATH : ${git}/bin \
      --set-default SSL_CERT_FILE ${cacert}/etc/ssl/certs/ca-bundle.crt \
      --set-default GIT_SSL_CAINFO ${cacert}/etc/ssl/certs/ca-bundle.crt
  '';
}
