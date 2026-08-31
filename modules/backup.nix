{
  pkgs,
  lib,
  config,
  backupFsUuid,
  ...
}: let
  cfg = config.myBackup;
in {
  # Optional, host-specific knobs. Plain `arg ? default` function
  # parameters don't work for this: NixOS's module-arg machinery always
  # resolves every declared parameter through `_module.args`, ignoring the
  # Nix-level default, and errors if a host never set it. Real options with
  # `mkOption`/`default` don't have that problem.
  options.myBackup = {
    ignoreFsUuid = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Filesystem UUID of a sibling partition on the backup drive that
        should never be auto-mounted (e.g. an unrelated encrypted volume).
      '';
    };
    daily = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Also trigger the backup on a daily timer, for hosts where the
        drive stays permanently connected instead of being hotplugged.
      '';
    };
  };

  config = {
    # Mountpoint for the backup drive. Exists even with the drive unplugged;
    # systemd only actually mounts something on top of it once the partition
    # with this UUID appears.
    systemd.tmpfiles.rules = [
      "d /mnt/backup 0755 root root -"
    ];

    # --- Mount ----------------------------------------------------------------
    fileSystems."/mnt/backup" = {
      device = "/dev/disk/by-uuid/${backupFsUuid}";
      fsType = "ext4";
      options = [
        "nofail"
        "x-systemd.device-timeout=5s"
      ];
    };

    # --- Trigger ----------------------------------------------------------------
    # Fires the instant udev sees the partition (by UUID), regardless of
    # whether anyone's logged in. SYSTEMD_WANTS just starts the unit —
    # systemd's own dependency graph (Requires/After on the mount, below)
    # makes it wait for the mount to actually finish before the backup runs.
    services.udev.extraRules =
      ''
        ACTION=="add", SUBSYSTEM=="block", ENV{ID_FS_UUID}=="${backupFsUuid}", TAG+="systemd", ENV{SYSTEMD_WANTS}+="backintime-backup.service"
      ''
      # The backup drive's other partition (e.g. an encrypted volume unrelated
      # to this system) — tell udisks2 to ignore it outright so nothing
      # auto-mounts it just because the drive got plugged in.
      # Matches "add" and "change": udisks2 can end up exporting the device
      # from a later "change" event (e.g. re-probe after the LUKS header
      # settles) that an "add"-only rule never covers, silently letting the
      # unlock prompt back in.
      + lib.optionalString (cfg.ignoreFsUuid != null) ''
        ACTION=="add|change", SUBSYSTEM=="block", ENV{ID_FS_UUID}=="${cfg.ignoreFsUuid}", ENV{UDISKS_IGNORE}="1"
      '';

    # --- Backup -----------------------------------------------------------------
    # Runs as fabian: no graphical session is needed for a systemd service to
    # run as a normal user, and running as fabian means snapshots land under
    # the same framenix/fabian/1 folder the desktop BackInTime GUI expects,
    # so backups are browsable there with no extra (root/polkit) setup.
    systemd.services.backintime-backup = {
      description = "Back In Time backup (triggered by backup-drive connect)";
      requires = ["mnt-backup.mount"];
      after = ["mnt-backup.mount"];
      serviceConfig = {
        Type = "oneshot";
        User = "fabian";
        # At most one backup per day: skip (without failing the unit) if the
        # newest snapshot is less than 24h old. Guards against re-triggering
        # on every reseat/replug of the same drive in a single day.
        ExecCondition = "${pkgs.writeShellScript "backintime-daily-guard" ''
          set -euo pipefail
          dir="/mnt/backup/backintime/${config.networking.hostName}/fabian/1"
          if [ -d "$dir" ] && find "$dir" -mindepth 1 -maxdepth 1 -newermt '-1 day' | grep -q .; then
            echo "Last snapshot is less than 24h old, skipping."
            exit 1
          fi
        ''}";
        ExecStart = "${pkgs.backintime-common}/bin/backintime --profile 1 --config /home/fabian/.config/backintime/config backup --quiet";
      };
    };

    # --- Daily timer -------------------------------------------------------------
    # For hosts where the backup drive stays permanently connected (desktops)
    # rather than getting plugged in occasionally (laptops): the udev hotplug
    # trigger above never fires again after the initial boot-time mount, so
    # give those hosts an explicit daily nudge instead. The ExecCondition
    # above still applies, so this is a no-op if a backup already ran today.
    systemd.timers.backintime-backup = lib.mkIf cfg.daily {
      description = "Daily trigger for Back In Time backup";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };
  };
}
