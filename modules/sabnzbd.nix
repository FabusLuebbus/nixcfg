{ ... }:

{
  # =========================================================================
  # SABnzbd — Usenet download client
  #
  # Native NixOS module (services.sabnzbd), same reasoning as Home
  # Assistant in modules/home-assistant.nix: upgrade/rollback stays a
  # plain nixos-rebuild instead of a separately-managed container image.
  # =========================================================================

  services.sabnzbd = {
    enable = true;
    # Opens 8080/tcp. LAN-only home server, same posture as Home
    # Assistant's dashboard — reachable from your own browser, not just
    # from the Hermes agent.
    openFirewall = true;
  };

  # Usenet server credentials, download categories, and the complete/temp
  # folder paths are all first-run web-UI configuration (state, not
  # declarative config) — set those up at http://servnix:8080 once the
  # service is running. Once the data drive(s) noted in
  # hosts/servnix/default.nix are mounted, point SABnzbd's "Complete
  # Folder" at a subdirectory of that mount rather than the default under
  # /var/lib/sabnzbd — downloads add up fast and a small internal SSD is
  # not where you want them landing.
}
