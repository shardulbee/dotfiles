# Bootstrap via admin access before enabling the source-transfer workflow:
# sudo nixos-rebuild switch --flake .#sharchy
# Keep personal SSH access open; the deploy key accepts only deploy <SHA>
# with a source tar on stdin. This authorizes root execution of that source.
{ lib, pkgs, ... }:
let
  hostScript = pkgs.replaceVars ../scripts/deploy-sharchy-host.py {
    nix = "${pkgs.nix}/bin/nix";
    nixEnv = "${pkgs.nix}/bin/nix-env";
    path = lib.makeBinPath [ pkgs.git pkgs.nix pkgs.coreutils pkgs.bash pkgs.systemd ];
  };
  host = pkgs.writeShellScriptBin "deploy-sharchy-host" ''
    exec ${pkgs.python3}/bin/python3 -I ${hostScript} "$@"
  '';
  dispatch = pkgs.writeShellScript "sharchy-deploy-ssh" ''
    set -euo pipefail
    if [[ ! "''${SSH_ORIGINAL_COMMAND:-}" =~ ^deploy\ ([0-9a-f]{40})$ ]]; then
      echo 'Only: deploy <40-character commit ID>' >&2
      exit 1
    fi
    exec /run/wrappers/bin/sudo -n ${host}/bin/deploy-sharchy-host "''${BASH_REMATCH[1]}"
  '';
in
{
  users.groups.dotfiles-deploy = { };
  users.users.dotfiles-deploy = {
    isSystemUser = true;
    group = "dotfiles-deploy";
    home = "/var/empty";
    createHome = false;
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      ''restrict,command="${dispatch}" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJo9B32sfzU4LF4SATBenldO248t4BadFcUNG9y6T1Kx dotfiles-deploy''
    ];
  };
  security.sudo.extraRules = [{
    users = [ "dotfiles-deploy" ];
    runAs = "root";
    commands = [{ command = "${host}/bin/deploy-sharchy-host"; options = [ "NOPASSWD" ]; }];
  }];
  services.openssh.extraConfig = ''
    Match User dotfiles-deploy
      ForceCommand ${dispatch}
      DisableForwarding yes
      PermitTTY no
      PermitUserRC no
    Match all
  '';
}
