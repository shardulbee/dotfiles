# Bootstrap via admin access before enabling the source-transfer workflow:
# sudo darwin-rebuild switch --flake .#macbook
# Requires Remote Login enabled and UID/GID 498 unused on first activation.
# The deploy key accepts only deploy <SHA> with a source tar on stdin.
# This authorizes root execution of that source; personal SSH stays unchanged.
{ lib, pkgs, ... }:
let
  hostScript = pkgs.replaceVars ../scripts/deploy-turbogadget-host.py {
    nix = "${pkgs.nix}/bin/nix";
    nixEnv = "${pkgs.nix}/bin/nix-env";
    path = lib.makeBinPath [
      pkgs.git
      pkgs.nix
      pkgs.coreutils
      pkgs.bash
    ];
  };
  host = pkgs.writeShellScriptBin "deploy-turbogadget-host" ''
    exec ${pkgs.python3}/bin/python3 -I ${hostScript} "$@"
  '';
  dispatch = pkgs.writeShellScript "dotfiles-deploy-ssh" ''
    set -euo pipefail
    if [[ ! "''${SSH_ORIGINAL_COMMAND:-}" =~ ^deploy\ ([0-9a-f]{40})$ ]]; then
      echo 'Only: deploy <40-character commit ID>' >&2
      exit 1
    fi
    exec /usr/bin/sudo -n ${host}/bin/deploy-turbogadget-host "''${BASH_REMATCH[1]}"
  '';
in
{
  users.knownUsers = [ "dotfiles-deploy" ];
  users.knownGroups = [ "dotfiles-deploy" ];
  users.groups.dotfiles-deploy.gid = 498;
  users.users.dotfiles-deploy = {
    uid = 498;
    gid = 498;
    isHidden = true;
    home = "/var/empty";
    createHome = false;
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = [
      ''restrict,command="${dispatch}" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJo9B32sfzU4LF4SATBenldO248t4BadFcUNG9y6T1Kx dotfiles-deploy''
    ];
  };

  security.sudo.extraConfig = ''
    dotfiles-deploy ALL=(root) NOPASSWD: ${host}/bin/deploy-turbogadget-host
  '';
  # AllowUsers entries accumulate. Keep the existing 050-key-only.conf intact.
  environment.etc."ssh/sshd_config.d/049-dotfiles-deploy.conf".text = ''
    AllowUsers dotfiles-deploy
  '';
  system.activationScripts.postActivation.text = ''
    if /usr/bin/dscl . -read /Groups/com.apple.access_ssh >/dev/null 2>&1; then
      /usr/sbin/dseditgroup -o edit -a dotfiles-deploy -t user com.apple.access_ssh
    fi
  '';
}
