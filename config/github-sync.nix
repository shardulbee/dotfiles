{ linux }:
{ lib, pkgs, ... }:
let
  storage = if linux then "/var/lib/github-checkouts" else "/var/db/github-checkouts";
  github-sync = pkgs.callPackage ../packages/github-sync.nix { };
  command = "${github-sync}/bin/github-sync ${storage}";
  sudo = if linux then "/run/wrappers/bin/sudo" else "/usr/bin/sudo";
  refresh = pkgs.writeShellApplication {
    name = "github-checkouts-refresh";
    runtimeInputs = [ pkgs.gh ];
    text = ''
      gh auth token --hostname github.com \
        | ${sudo} -n -H -u github-sync ${command}
    '';
  };
in
lib.mkMerge [
  {
    # Only this exact command can run passwordlessly as the writer account.
    security.sudo.extraConfig = ''
      shardul ALL=(github-sync) NOPASSWD: ${command}
    '';

    home-manager.users.shardul = { config, ... }: {
      home.packages = [ refresh ];
      home.file.".cache/checkouts/github.com/shardulbee".source =
        config.lib.file.mkOutOfStoreSymlink "${storage}/github.com/shardulbee";
      xdg.configFile."git/config".text = ''
        [safe]
          directory = ${storage}/github.com/shardulbee/*
      '';

      systemd.user.services.github-sync = lib.mkIf linux {
        Unit.Description = "Refresh read-only private GitHub checkouts";
        Service = {
          Type = "oneshot";
          ExecStart = "${refresh}/bin/github-checkouts-refresh";
          TimeoutStartSec = "infinity";
        };
      };
      systemd.user.timers.github-sync = lib.mkIf linux {
        Unit.Description = "Refresh GitHub checkouts every 30 seconds";
        Timer = {
          OnStartupSec = "10s";
          OnCalendar = "*-*-* *:*:00,30";
          AccuracySec = "1s";
        };
        Install.WantedBy = [ "timers.target" ];
      };

      launchd.agents.github-sync = lib.mkIf (!linux) {
        enable = true;
        config = {
          ProgramArguments = [ "${refresh}/bin/github-checkouts-refresh" ];
          RunAtLoad = true;
          StartInterval = 30;
          EnvironmentVariables.HOME = config.home.homeDirectory;
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/github-sync.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/github-sync.log";
        };
      };
    };
  }
  (lib.optionalAttrs linux {
    users.groups.github-checkouts.members = [ "shardul" ];
    users.users.github-sync = {
      isSystemUser = true;
      group = "github-checkouts";
      home = storage;
    };
    systemd.tmpfiles.rules = [
      "d ${storage} 0750 github-sync github-checkouts -"
      "d ${storage}/github.com 0750 github-sync github-checkouts -"
      "d ${storage}/github.com/shardulbee 0750 github-sync github-checkouts -"
    ];
  })
  (lib.optionalAttrs (!linux) {
    users.knownUsers = [ "github-sync" ];
    users.knownGroups = [ "github-checkouts" ];
    users.groups.github-checkouts = {
      gid = 499;
      members = [ "shardul" ];
    };
    users.users.github-sync = {
      uid = 499;
      gid = 499;
      isHidden = true;
      home = storage;
      shell = "/usr/bin/false";
    };
    system.activationScripts.postActivation.text = ''
      install -d -o github-sync -g github-checkouts -m 0750 \
        ${storage} ${storage}/github.com ${storage}/github.com/shardulbee
    '';
  })
]
