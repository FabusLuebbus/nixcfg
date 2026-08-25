{ pkgs, config, backupFsUuid, ... }:

{
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
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="block", ENV{ID_FS_UUID}=="${backupFsUuid}", TAG+="systemd", ENV{SYSTEMD_WANTS}+="backintime-backup.service"
  '';

  # --- Backup -----------------------------------------------------------------
  # Runs as fabian: no graphical session is needed for a systemd service to
  # run as a normal user, and running as fabian means snapshots land under
  # the same framenix/fabian/1 folder the desktop BackInTime GUI expects,
  # so backups are browsable there with no extra (root/polkit) setup.
  systemd.services.backintime-backup = {
    description = "Back In Time backup (triggered by backup-drive connect)";
    requires = [ "mnt-backup.mount" ];
    after = [ "mnt-backup.mount" ];
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
      ExecStart =
        "${pkgs.backintime-common}/bin/backintime --profile 1 --config /home/fabian/.config/backintime/config backup --quiet";
    };
  };
}
