{ pkgs, ... }:

{
  # No display manager, no desktop environment — this host stays headless.
  # Do NOT import modules/desktop.nix here.

  # ---------------------------------------------------------------------- SSH
  # This machine only exists to be reached remotely, so SSH is the front
  # door from day one, and it's key-only.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Bans an IP after repeated failed SSH attempts — worth having once this
  # box is reachable from outside the LAN (port-forwarded or otherwise).
  services.fail2ban.enable = true;

  # ------------------------------------------------------------------ storage
  # "Some hard drives" plural, some of them presumably old — SMART failure
  # warnings matter more here than on a laptop. Logs to the journal
  # (`journalctl -u smartd`); no mail transport is set up for alerts.
  services.smartd = {
    enable = true;
    autodetect = true;
  };

  # File sharing for whatever ends up on the drives. Left disabled — pick
  # Samba (Windows/mixed clients) or NFS (Linux-only, lighter) once the
  # drives are in and you know who's connecting, then fill in the shares.
  # services.samba = {
  #   enable = true;
  #   openFirewall = true;
  #   settings = {
  #     global = {
  #       "workgroup" = "WORKGROUP";
  #       "server string" = "servnix";
  #       "security" = "user";
  #     };
  #     # data = {
  #     #   path = "/mnt/data";
  #     #   browseable = "yes";
  #     #   "read only" = "no";
  #     #   "guest ok" = "no";
  #     # };
  #   };
  # };
  # services.nfs.server.enable = true;

  # --------------------------------------------------------------- containers
  # Most server-typical workloads (media server, *arr stack, dashboards,
  # ...) are easiest to run as containers rather than one packaged NixOS
  # service at a time.
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    autoPrune.dates = "weekly";
  };

  # ------------------------------------------------------------------ packages
  environment.systemPackages = with pkgs; [
    smartmontools
    lm_sensors
    iotop
    ethtool
  ];
}
