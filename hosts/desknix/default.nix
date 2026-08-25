{ hostname, ... }:

{
  imports = [
    # Generated on the machine itself by the installer. Doesn't exist yet —
    # after `nixos-install`, copy it in before the first dry-build:
    #   cp /etc/nixos/hardware-configuration.nix ~/nixcfg/hosts/desknix/hardware-configuration.nix
    ./hardware-configuration.nix

    ../../modules/base.nix
    ../../modules/desktop.nix
    ../../modules/dev.nix
    ../../modules/nvidia.nix
    ../../modules/backup.nix
  ];

  networking.hostName = hostname;

  # Filesystem UUID of this machine's backup partition. Placeholder — the
  # backup drive plugged into this desktop has a different UUID than
  # framenix's. Find it on-site once the drive is connected:
  #   lsblk -f
  # or:
  #   sudo blkid
  # then replace this value before the first `switch`.
  _module.args.backupFsUuid = "00000000-0000-0000-0000-000000000000";

  # UEFI bootloader. If the installer used legacy BIOS/GRUB instead, delete
  # these three lines and keep whatever it generated.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 20; # keep 20 rollback entries
  boot.loader.efi.canTouchEfiVariables = true;

  # DO NOT CHANGE THIS after install. It is not a version number to keep
  # current — it pins stateful-data compatibility to the release you first
  # installed. Changing it can silently break databases and service state.
  system.stateVersion = "26.05";
}
