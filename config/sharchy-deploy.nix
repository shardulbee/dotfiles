# Bootstrap via admin access before enabling the immutable-source workflow:
# sudo nixos-rebuild switch --flake .#sharchy
# Keep personal SSH access open. The deploy key can only import Nix store paths
# or activate one imported source; activating it authorizes root execution.
{ pkgs, ... }:
let
  host = pkgs.writeShellScriptBin "deploy-sharchy-host" ''
    set -euo pipefail
    if [[ $# -ne 1 || ! $1 =~ ^/nix/store/[0-9a-z]{32}-source$ ]]; then
      echo 'usage: deploy-sharchy-host /nix/store/<hash>-source' >&2
      exit 2
    fi

    exec 9>/run/lock/dotfiles-deploy.lock
    ${pkgs.util-linux}/bin/flock 9

    old_system="$(${pkgs.coreutils}/bin/readlink -f /run/current-system)"
    new_system="$(${pkgs.nix}/bin/nix build \
      --no-link \
      --print-out-paths \
      --option accept-flake-config false \
      --no-write-lock-file \
      "path:$1#nixosConfigurations.sharchy.config.system.build.toplevel")"
    if [[ ! $new_system =~ ^/nix/store/[0-9a-z]{32}-nixos-system-sharchy-[^/[:space:]]+$ ]]; then
      echo 'Build did not return one Sharchy NixOS system store path' >&2
      exit 1
    fi

    ${pkgs.nix}/bin/nix-env --profile /nix/var/nix/profiles/system --set "$new_system"
    status=0
    "$new_system/bin/switch-to-configuration" switch || status=$?
    if [[ $status -eq 0 && "$(${pkgs.coreutils}/bin/readlink -f /run/current-system)" == "$new_system" ]]; then
      echo "Activated $new_system"
      exit 0
    fi

    [[ $status -ne 0 ]] || status=1
    echo 'Activation failed; restoring prior system' >&2
    ${pkgs.nix}/bin/nix-env --profile /nix/var/nix/profiles/system --set "$old_system"
    "$old_system/bin/switch-to-configuration" switch
    exit "$status"
  '';
  dispatch = pkgs.writeShellScript "sharchy-deploy-ssh" ''
    set -euo pipefail
    case "''${SSH_ORIGINAL_COMMAND:-}" in
      'nix-daemon --stdio') exec ${pkgs.nix}/bin/nix-daemon --stdio ;;
      deploy\ /nix/store/*-source)
        source="''${SSH_ORIGINAL_COMMAND#deploy }"
        [[ $source =~ ^/nix/store/[0-9a-z]{32}-source$ ]] || exit 1
        exec /run/wrappers/bin/sudo -n ${host}/bin/deploy-sharchy-host "$source"
        ;;
      *) echo 'Only Nix store import and deployment are allowed' >&2; exit 1 ;;
    esac
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
