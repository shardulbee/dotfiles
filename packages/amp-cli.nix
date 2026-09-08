{ amp-cli, fetchurl, stdenvNoCC }:

let
  version = "0.0.1788858037-gc9d85c";
  system = stdenvNoCC.hostPlatform.system;
in
amp-cli.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://static.ampcode.com/cli/${version}/amp-${
      {
        x86_64-linux = "linux-x64-baseline";
        aarch64-darwin = "darwin-arm64";
      }
      .${system}
    }.gz";
    hash =
      {
        x86_64-linux = "sha256-uYI9eZM6n8/+1G0n+hMpoB+bp24Aw5GJPF1dcy2DXAY=";
        aarch64-darwin = "sha256-+Lz21YKrA8iwkk+xNVC6Uh5CXDIKpy7rgjRWvh1VlBg=";
      }
      .${system};
  };
})
