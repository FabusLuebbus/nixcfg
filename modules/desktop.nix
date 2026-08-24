{ pkgs, ... }:

{
  services.xserver.enable = true;

  # GNOME. To swap to KDE Plasma instead, replace the two lines below with:
  #   services.displayManager.sddm.enable = true;
  #   services.desktopManager.plasma6.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

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
    gnomeExtensions.appindicator
  ];

  # Portals — needed for Flatpak and screen sharing to behave.
  xdg.portal.enable = true;
  services.flatpak.enable = true;
}
