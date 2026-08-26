{ ... }:

{
  # =========================================================================
  # Home Assistant
  #
  # Run through nixpkgs' native `services.home-assistant` module rather
  # than the official Docker image: components are declared here and built
  # reproducibly into one Python environment, so a `nixos-rebuild switch`
  # is the entire upgrade/rollback story, same as everything else in this
  # repo. The trade-off worth knowing: HACS and other community/custom
  # integrations that aren't packaged in nixpkgs don't work with this
  # approach (they expect to pip-install themselves at runtime, which the
  # store's read-only filesystem prevents) — if you end up needing one of
  # those, the official Docker image via `virtualisation.oci-containers`
  # (same mechanism as ./hermes-agent.nix) is the fallback, at the cost of
  # losing the declarative-upgrade story for whatever it manages itself.
  # =========================================================================

  services.home-assistant = {
    enable = true;

    # Trim this to the integrations you actually use — every extra
    # component adds its own Python dependency closure to the build.
    extraComponents = [
      "met" # weather; part of the default onboarding flow
      "mobile_app" # the companion phone app
      "esphome" # ESPHome-flashed sensors/switches, common DIY smart-home path
    ];

    config = {
      # Everything else (areas, entities, automations, dashboards) is
      # normal to do through the UI after first boot — it's persisted in
      # /var/lib/hass, which this repo does NOT track (state, not config).
      homeassistant = {
        name = "Home";
        time_zone = "Europe/Berlin";
        unit_system = "metric";
        temperature_unit = "C";
      };
      http = {
        server_host = "0.0.0.0";
      };
      default_config = { };
    };

    # Opens 8123/tcp — this is a LAN-only home server, not something to
    # expose further without a reverse proxy + auth in front of it.
    openFirewall = true;
  };

  # mDNS/SSDP-based discovery (most smart-home integrations rely on one or
  # the other to find devices) needs Avahi, which isn't on by default on a
  # headless host the way it is via modules/desktop.nix.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
