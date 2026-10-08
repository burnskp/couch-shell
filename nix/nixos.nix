{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.couch-shell-btrfs;
  hmUsers = lib.attrByPath [ "home-manager" "users" ] { } config;
  consumers = lib.filterAttrs (
    _: user:
    lib.attrByPath [ "programs" "couch-shell" "enable" ] false user
    && lib.attrByPath [ "programs" "couch-shell" "bar" "disk" "btrfs" "enable" ] false user
  ) hmUsers;
  intervals = lib.mapAttrsToList (
    _: user: user.programs.couch-shell.bar.disk.btrfs.pollInterval
  ) consumers;
  collector = pkgs.callPackage ./btrfs-collector.nix { };
in
{
  options.services.couch-shell-btrfs = {
    enable = lib.mkEnableOption "the socket-activated couch-shell Btrfs collector";
    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Users allowed to read the shared Btrfs report, including all filesystem and subvolume names.";
    };
    pollInterval = lib.mkOption {
      type = lib.types.ints.positive;
      default = 300;
      description = "Minimum seconds between collection attempts, including failures.";
    };
  };
  config = lib.mkMerge [
    {
      services.couch-shell-btrfs = {
        enable = lib.mkDefault (consumers != { });
        users = lib.attrNames consumers;
        pollInterval = lib.mkDefault (
          if intervals == [ ] then 300 else lib.foldl' lib.min (builtins.head intervals) intervals
        );
      };
    }
    (lib.mkIf cfg.enable {
      users.groups.couch-shell-btrfs.members = cfg.users;
      systemd.tmpfiles.rules = [ "d /run/couch-shell 0750 root couch-shell-btrfs -" ];
      systemd.sockets.couch-shell-btrfs = {
        description = "Couch Shell Btrfs report socket";
        wantedBy = [ "sockets.target" ];
        socketConfig = {
          ListenStream = "/run/couch-shell/btrfs.sock";
          SocketUser = "root";
          SocketGroup = "couch-shell-btrfs";
          SocketMode = "0660";
          DirectoryMode = "0750";
          RemoveOnStop = true;
        };
      };
      systemd.services.couch-shell-btrfs = {
        description = "Couch Shell on-demand Btrfs collector";
        requires = [ "couch-shell-btrfs.socket" ];
        after = [ "couch-shell-btrfs.socket" ];
        serviceConfig = {
          ExecStart = "${collector}/bin/couch-shell-btrfs-server ${toString cfg.pollInterval}";
          User = "root";
          Group = "couch-shell-btrfs";
          UMask = "0027";
          CapabilityBoundingSet = [
            "CAP_SYS_ADMIN"
            "CAP_DAC_READ_SEARCH"
          ];
          SystemCallFilter = [ "~@mount" ];
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          MemoryHigh = "192M";
          MemoryMax = "256M";
          MemorySwapMax = "0";
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ReadWritePaths = [ "/run/couch-shell" ];
          ProtectHome = "read-only";
          RestrictAddressFamilies = [ "AF_UNIX" ];
          RestrictSUIDSGID = true;
          LockPersonality = true;
          TimeoutStopSec = 10;
          Restart = "on-failure";
        };
      };
    })
  ];
}
