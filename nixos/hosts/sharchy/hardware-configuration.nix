# Placeholder hardware config so `nix flake check` can evaluate.
# Replace this file with the output from `nixos-generate-config` on sharchy
# before installing or switching this host.
{ lib, ... }:

{
  fileSystems."/" = {
    device = lib.mkDefault "/dev/disk/by-label/nixos";
    fsType = lib.mkDefault "ext4";
  };
}
