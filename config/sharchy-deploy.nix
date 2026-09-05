# Bootstrap after publishing the reviewed main, from a clean checkout on Sharchy:
# git fetch origin && git merge --ff-only origin/main
# Require HEAD == origin/main == the reviewed SHA, and empty git status --porcelain.
# sudo flock /run/lock/sharchy-deploy.lock nixos-rebuild switch --flake .#sharchy
# First verify a personal SSH key works and shardul's gh login can read this repo.
# Keep that admin session open: activation moves the orb key off shardul at once.
# Then run orb-deploy-sharchy from the clean published orb checkout. Verify its
# receipt and /run/current-system via personal SSH; test shell/upload rejection
# and that the orb key no longer logs in as shardul. No key rotation is needed.
# If an installed-helper limitation prevents deployment, activate its fix through
# local/admin access. Fetched helper changes take effect only after activation.
{ lib, pkgs, ... }:
let
  hostScript = pkgs.replaceVars ../scripts/deploy-sharchy-host.py {
    git = "${pkgs.git}/bin/git";
    gh = "${pkgs.gh}/bin/gh";
    runuser = "${pkgs.util-linux}/bin/runuser";
    env = "${pkgs.coreutils}/bin/env";
    nix = "${pkgs.nix}/bin/nix";
    nixEnv = "${pkgs.nix}/bin/nix-env";
    path = lib.makeBinPath [ pkgs.git pkgs.gh pkgs.nix pkgs.coreutils pkgs.bash pkgs.systemd ];
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
      ''restrict,command="${dispatch}" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJo9B32sfzU4LF4SATBenldO248t4BadFcUNG9y6T1Kx amp-dotfiles-deploy''
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
