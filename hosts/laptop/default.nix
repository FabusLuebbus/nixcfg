{ hostname, ... }:

{
  imports = [
    # Generated on the machine itself by the installer.
    # Copy /etc/nixos/hardware-configuration.nix into this folder on day one.
    ./hardware-configuration.nix

    ../../modules/base.nix
    ../../modules/desktop.nix
    ../../modules/dev.nix
  ];

  networking.hostName = hostname;

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
