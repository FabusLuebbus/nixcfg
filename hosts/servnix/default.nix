{ hostname, ... }:

{
  imports = [
    # Generated on the machine itself by the installer. Doesn't exist yet —
    # after `nixos-install`, copy it in before the first dry-build:
    #   cp /etc/nixos/hardware-configuration.nix ~/nixcfg/hosts/servnix/hardware-configuration.nix
    ./hardware-configuration.nix

    ../../modules/base.nix
    ../../modules/server.nix
  ];

  networking.hostName = hostname;

  # UEFI bootloader. Most laptops from the last ~decade are UEFI-capable —
  # if the installer used legacy BIOS/GRUB instead, delete these three
  # lines and keep whatever it generated.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 20; # keep 20 rollback entries
  boot.loader.efi.canTouchEfiVariables = true;

  # This is a laptop chassis running headless with the lid closed (no
  # monitor/keyboard attached once it's racked/shelved somewhere). Without
  # this, systemd-logind suspends the machine the moment the lid shuts,
  # which defeats the entire point of it being a server.
  services.logind.extraConfig = ''
    HandleLidSwitch=ignore
    HandleLidSwitchExternalPower=ignore
    HandleLidSwitchDocked=ignore
  '';

  # ------------------------------------------------------------- data drives
  # The "some hard drives" this server is being built around. Add one
  # fileSystems entry per drive once they're physically connected and you
  # know their UUIDs (`lsblk -f` / `sudo blkid`), e.g.:
  #
  #   fileSystems."/mnt/data" = {
  #     device = "/dev/disk/by-uuid/CHANGEME";
  #     fsType = "ext4"; # or whatever you end up formatting them as
  #     options = [ "nofail" ];
  #   };
  #
  # More than one drive and want them pooled instead of mounted separately?
  # Worth deciding the layout before formatting rather than after:
  #   - mergerfs: simple JBOD-style pooling of independently-formatted disks
  #   - ZFS (raidz/mirror): redundancy + checksums, but needs
  #     `boot.supportedFilesystems = [ "zfs" ]` and a unique `networking.hostId`

  # DO NOT CHANGE THIS after install. It is not a version number to keep
  # current — it pins stateful-data compatibility to the release you first
  # installed. Changing it can silently break databases and service state.
  system.stateVersion = "26.05";
}
