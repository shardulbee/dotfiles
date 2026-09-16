# Bootstrap via admin access before enabling the immutable-source workflow:
# sudo darwin-rebuild switch --flake .#macbook
# Requires Remote Login enabled and UID/GID 498 unused on first activation.
# The deploy key can only import Nix store paths or activate one imported source;
# activating it authorizes root execution. Personal SSH stays unchanged.
{ lib, pkgs, ... }:
let
  path = lib.makeBinPath [ pkgs.nix pkgs.coreutils pkgs.bash ];
  locked = pkgs.writeShellScript "deploy-turbogadget-locked" ''
    set -euo pipefail

    old_system="$(${pkgs.coreutils}/bin/readlink -f /run/current-system)"
    new_system="$(/usr/bin/sudo -n -H -u shardul /usr/bin/env -i \
      HOME=/Users/shardul USER=shardul LOGNAME=shardul PATH=${path} \
      SSL_CERT_FILE=/etc/ssl/cert.pem NIX_SSL_CERT_FILE=/etc/ssl/cert.pem \
      ${pkgs.nix}/bin/nix build \
      --no-link \
      --print-out-paths \
      --option accept-flake-config false \
      --no-write-lock-file \
      "path:$1#darwinConfigurations.macbook.system")"
    if [[ ! $new_system =~ ^/nix/store/[0-9a-z]{32}-darwin-system-[^/[:space:]]+$ ]]; then
      echo 'Build did not return one Darwin system store path' >&2
      exit 1
    fi
    if [[ -e $new_system/activate-user ]] && ! ${pkgs.gnugrep}/bin/grep -q '# nix-darwin: deprecated' "$new_system/activate-user"; then
      echo 'Legacy user activation is not supported; nothing activated' >&2
      exit 1
    fi

    ${pkgs.nix}/bin/nix-env --profile /nix/var/nix/profiles/system --set "$new_system"
    status=0
    "$new_system/activate" || status=$?
    if [[ $status -eq 0 && "$(${pkgs.coreutils}/bin/readlink -f /run/current-system)" == "$new_system" ]]; then
      echo "Activated $new_system"
      exit 0
    fi

    [[ $status -ne 0 ]] || status=1
    echo 'Activation failed; restoring prior system' >&2
    ${pkgs.nix}/bin/nix-env --profile /nix/var/nix/profiles/system --set "$old_system"
    "$old_system/activate"
    exit "$status"
  '';
  host = pkgs.writeShellScriptBin "deploy-turbogadget-host" ''
    set -euo pipefail
    if [[ $# -ne 1 || ! $1 =~ ^/nix/store/[0-9a-z]{32}-source$ ]]; then
      echo 'usage: deploy-turbogadget-host /nix/store/<hash>-source' >&2
      exit 2
    fi
    exec /usr/bin/lockf -k /var/run/dotfiles-deploy.lock ${locked} "$1"
  '';
  dispatch = pkgs.writeShellScript "dotfiles-deploy-ssh" ''
    set -euo pipefail
    case "''${SSH_ORIGINAL_COMMAND:-}" in
      'nix-daemon --stdio') exec ${pkgs.nix}/bin/nix-daemon --stdio ;;
      deploy\ /nix/store/*-source)
        source="''${SSH_ORIGINAL_COMMAND#deploy }"
        [[ $source =~ ^/nix/store/[0-9a-z]{32}-source$ ]] || exit 1
        exec /usr/bin/sudo -n ${host}/bin/deploy-turbogadget-host "$source"
        ;;
      *) echo 'Only Nix store import and deployment are allowed' >&2; exit 1 ;;
    esac
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
