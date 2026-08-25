{ pkgs, ... }:

{
  services.xserver.enable = true;

  # GNOME. To swap to KDE Plasma instead, replace the two lines below with:
  #   services.displayManager.sddm.enable = true;
  #   services.desktopManager.plasma6.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  # environment.systemPackages does NOT put a package's typelib on the
  # session's GI_TYPELIB_PATH — gnome-shell needs it via sessionPath instead.
  # Without this, extensions that use GMenu (e.g. ArcMenu) fail with
  # "Typelib file for namespace 'GMenu' (any version) not found".
  # https://github.com/NixOS/nixpkgs/issues/325497
  services.desktopManager.gnome.sessionPath = [ pkgs.gnome-menus ];

  # Keyboard layout for the graphical session.
  services.xserver.xkb = {
    layout = "de";
    variant = "";
  };

  # ------------------------------------------------------------------- audio
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ----------------------------------------------------------------- printing
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # ------------------------------------------------------------------ laptop
  services.libinput.enable = true;
  services.power-profiles-daemon.enable = true;
  services.fprintd.enable = true;
  # fprintd.enable defaults fprintAuth to true for every PAM service,
  # which would let a fingerprint satisfy `sudo` too. Restrict it to
  # GDM's own login/unlock services only.
  security.pam.services = {
    sudo.fprintAuth = false;
    su.fprintAuth = false;
    login.fprintAuth = false;
    polkit-1.fprintAuth = false;
  };

  # -------------------------------------------------------- trim GNOME bloat
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-music
    epiphany # GNOME Web
    geary # mail
    totem # video player
  ];

  environment.systemPackages = with pkgs; [
    gnome-tweaks
    dconf-editor
  ];

  # Portals — needed for Flatpak and screen sharing to behave.
  xdg.portal.enable = true;
  services.flatpak.enable = true;
}
