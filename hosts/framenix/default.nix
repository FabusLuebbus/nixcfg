{ hostname, ... }:

{
  imports = [
    # Generated on the machine itself by the installer.
    # Copy /etc/nixos/hardware-configuration.nix into this folder on day one.
    ./hardware-configuration.nix

    ../../modules/base.nix
    ../../modules/desktop.nix
    ../../modules/dev.nix
    ../../modules/backup.nix
  ];

  networking.hostName = hostname;

  # Filesystem UUID of this machine's backup partition (unencrypted ext4).
  # Machine-specific — will differ on any other host, so it lives here
  # rather than in modules/backup.nix.
  _module.args.backupFsUuid = "b77d618a-8a32-4fa0-8753-2976ccb3b480";

  # The backup drive's other partition — unrelated to this system, never
  # to be auto-mounted when the drive is plugged in.
  myBackup.ignoreFsUuid = "896bc3ae-d5ed-418f-91ab-09a583c22af0";

  # UEFI bootloader. If your machine is legacy BIOS (unlikely on anything
  # modern), the installer-generated config will use GRUB instead — in that
  # case delete these three lines and keep what the installer produced.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 20; # keep 20 rollback entries
  boot.loader.efi.canTouchEfiVariables = true;

  # Newer kernel — nice for recent laptop hardware.
  # boot.kernelPackages = pkgs.linuxPackages_latest;

  # DO NOT CHANGE THIS after install. It is not a version number to keep
  # current — it pins stateful-data compatibility to the release you first
  # installed. Changing it can silently break databases and service state.
  system.stateVersion = "26.05";
}
