{ pkgs, backupFsUuid, ... }:

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
  # Runs as root: simplest way to reliably read every file under /home and
  # write into a drive that may get mounted headlessly, with no dependency
  # on a graphical session existing. BackInTime's GUI ships a polkit helper
  # specifically for browsing/restoring root-owned snapshots as a normal
  # user, so this doesn't block restores.
  systemd.services.backintime-backup = {
    description = "Back In Time backup (triggered by backup-drive connect)";
    requires = [ "mnt-backup.mount" ];
    after = [ "mnt-backup.mount" ];
    serviceConfig = {
      Type = "oneshot";
      # Debounce: wait 5 minutes after the mount is up, then re-check it's
      # still there before actually starting — covers both "briefly
      # reseated cable" and "unplugged again during the wait".
      ExecStartPre = [
        "${pkgs.coreutils}/bin/sleep 300"
        "${pkgs.util-linux}/bin/mountpoint -q /mnt/backup"
      ];
      ExecStart =
        "${pkgs.backintime-common}/bin/backintime --profile 1 --config /home/fabian/.config/backintime/config backup --quiet";
    };
  };
}
