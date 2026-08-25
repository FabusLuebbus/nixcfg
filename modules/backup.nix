{ pkgs, ... }:

let
  # Fixed name for the decrypted LUKS mapping — chosen by us, doesn't
  # depend on the physical drive, so it can be wired up before the drive
  # is ever connected.
  mapperName = "backupdrive";

  # LUKS UUID of the *encrypted* partition (not the filesystem inside it).
  # Unknown until the drive exists. Once connected once (even without a
  # keyfile yet — cryptsetup can still read the header), find it with:
  #   lsblk -f                     # or
  #   sudo cryptsetup luksUUID /dev/sdX1
  # and replace this placeholder in both places it's used below.
  luksUuid = "REPLACE-WITH-ACTUAL-LUKS-UUID";

  keyFile = "/etc/backup-drive.key";
in
{
  # Mountpoint for the decrypted volume. Exists even with the drive
  # unplugged; systemd only actually mounts something on top of it once
  # /dev/mapper/${mapperName} appears (see crypttab + udev rule below).
  systemd.tmpfiles.rules = [
    "d /mnt/backup 0755 root root -"
  ];

  # --- Unlock -----------------------------------------------------------
  # A crypttab entry auto-unlocks *any* block device carrying this LUKS
  # UUID as soon as it appears (systemd-cryptsetup-generator wires up the
  # udev matching itself — that's what makes hotplug work, `noauto` here
  # only means "don't block boot waiting for it").
  #
  # `keyFile` must exist at ${keyFile}, root-only-readable, and must NOT be
  # generated here or committed to git — it's the actual backup-drive
  # secret. One-time manual setup once the drive is connected:
  #   sudo dd if=/dev/urandom of=${keyFile} bs=512 count=4
  #   sudo chmod 400 ${keyFile}
  #   sudo cryptsetup luksAddKey /dev/sdX1 ${keyFile}   # prompts for the existing passphrase once
  environment.etc."crypttab".text = ''
    ${mapperName} UUID=${luksUuid} ${keyFile} luks,nofail,noauto,discard
  '';

  # --- Mount --------------------------------------------------------------
  # Fixed mapper device name, so — unlike the LUKS UUID above — this half
  # doesn't need the physical drive to be declared correctly now.
  fileSystems."/mnt/backup" = {
    device = "/dev/mapper/${mapperName}";
    fsType = "ext4"; # adjust if you format the inner filesystem differently
    options = [ "nofail" ];
  };

  # --- Trigger --------------------------------------------------------------
  # Fires the instant udev sees the encrypted partition (by the same LUKS
  # UUID as above), regardless of whether anyone's logged in. SYSTEMD_WANTS
  # just starts the unit — systemd's own dependency graph (Requires/After
  # on the mount, below) makes it wait for unlock + mount to actually finish
  # before the backup itself runs.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="block", ENV{ID_FS_UUID}=="${luksUuid}", TAG+="systemd", ENV{SYSTEMD_WANTS}+="backintime-backup.service"
  '';

  # --- Backup ---------------------------------------------------------------
  # Runs as root: simplest way to reliably read every file under /home
  # and write into a drive that's unlocked headlessly, with no dependency
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
