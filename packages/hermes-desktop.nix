{ hermes, stdenv }:

let
  upstream = hermes.packages.${stdenv.hostPlatform.system}.desktop;
in
upstream.overrideAttrs (old: {
  meta = (old.meta or { }) // {
    description = "Locally pinned ${old.meta.description}";
    platforms = [ "x86_64-linux" ];
  };
})
