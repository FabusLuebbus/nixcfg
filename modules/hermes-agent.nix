{ pkgs, ... }:

{
  # =========================================================================
  # Hermes Agent (Nous Research) — https://github.com/NousResearch/hermes-agent
  #
  # NOT a Docker image to pull — it's a `curl | bash`-installed CLI/daemon
  # (the `hermes` command) that bundles its own Python/Node runtime under
  # ~/.hermes. It has its own execution-sandboxing concept: one of its
  # built-in "terminal backends" (local/Docker/SSH/Singularity/Modal/...)
  # runs whatever shell commands the agent decides to run inside a Docker
  # container instead of directly on the host. That IS the "full access
  # inside its sandbox" boundary you want — set its backend to `docker`
  # (see the bootstrap steps below) rather than trying to wrap the whole
  # `hermes` process in a container ourselves, which isn't how it's built.
  #
  # ONLY install from the verified source: the official installer at
  # hermes-agent.nousresearch.com, or github.com/NousResearch/hermes-agent
  # directly. A web search for "Hermes Agent" turns up a cluster of
  # lookalike domains (hermes-agent.org, hermes-ai.net, hermes-agent.ai,
  # plus SEO blog spam) repeating suspiciously specific stats — don't
  # install from any of those.
  #
  # This module intentionally does NOT run the installer for you. Piping
  # an internet script into `bash` from inside a Nix module eval isn't
  # reproducible and isn't something to do unattended for a tool that gets
  # broad tool-calling access — read install.sh yourself first, then run
  # it manually as fabian:
  #   curl -fsSL https://hermes-agent.nousresearch.com/install.sh | less   # read it first
  #   curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
  #   hermes model               # point it at local ollama, or a cloud provider
  #   hermes config set <...>    # set the terminal/execution backend to `docker`
  #
  # ---- confining it to one part of the server ----------------------------
  # Two independent layers, per Hermes's own security docs, so a mistake in
  # one doesn't undo the other:
  #
  #  1. The docker terminal backend itself: the sandbox container only ever
  #     gets the bind mount(s) listed in docker_volumes — nothing else on
  #     this machine is even present in its filesystem namespace, so
  #     there's nothing to escape TO. Set this by hand in
  #     ~/.hermes/config.yaml (that file mixes config with API keys/session
  #     state per Hermes's docs, so — same reasoning as home/ssh.nix not
  #     committing private keys — Nix never writes it):
  #
  #       terminal:
  #         backend: docker
  #         docker_image: "nikolaik/python-nodejs:python3.11-nodejs20"
  #         docker_volumes:
  #           - "/srv/hermes-agent/workspace:/workspace"   # the ONLY thing it can touch
  #         docker_run_as_host_user: true   # files land owned by fabian, not root
  #         docker_network: true            # needed for web browsing/search tools
  #         container_cpu: 2
  #         container_memory: 4096          # MB; drop to ~1024 if you skip browser tools
  #         container_persistent: true
  #
  #       security:
  #         allow_private_urls: false   # keep the rest of your LAN off-limits to web tools
  #
  #  2. HERMES_WRITE_SAFE_ROOT (set on the systemd unit below, not a
  #     secret so Nix can own it): hard-blocks write_file/patch tool calls
  #     outside these prefixes regardless of terminal backend — belt and
  #     braces in case the backend ever gets switched back to `local`.
  #
  # ---- reaching Home Assistant and SABnzbd on this same box --------------
  # These do NOT go through the generic web tool, so they don't need
  # security.allow_private_urls flipped on (which would open the whole
  # RFC1918/loopback/link-local range to the model-driven web tools) — and
  # they don't touch the file/shell sandbox above at all. Both run as
  # purpose-built tool integrations instead, each scoped to exactly one
  # service:
  #
  #  - Home Assistant: Hermes ships a FIRST-PARTY toolset for this
  #    (ha_list_entities / ha_get_state / ha_list_services / ha_call_service),
  #    no MCP server needed. It activates automatically once HASS_TOKEN is
  #    set. Generate a Long-Lived Access Token from your HA user profile
  #    (Profile → Long-Lived Access Tokens → Create Token — NOT a regular
  #    session token, those 401), then add to ~/.hermes/.env (a secrets
  #    file; same reasoning as ~/.hermes/config.yaml, Nix never writes it):
  #
  #      HASS_TOKEN=<the long-lived token>
  #
  #    (HASS_URL defaults to http://homeassistant.local:8123, which
  #    resolves fine here via the Avahi enabled in modules/home-assistant.nix
  #    — or set HASS_URL=http://127.0.0.1:8123 explicitly, also fine since
  #    both run on servnix.) Worth knowing: this toolset has no granular
  #    entity/domain scoping of its own — the token grants full HA API
  #    access. Nous's own mitigation is blocking the service domains that
  #    would turn it into a code-execution pivot (shell_command,
  #    command_line, python_script, pyscript, hassio, rest_command).
  #
  #  - SABnzbd: no first-party toolset exists (as of this writing), and no
  #    well-established MCP server for it either. The closest fit found is
  #    github.com/ryanbrinn/arr-mcp (PyPI: arr-mcp-server, MIT) — covers
  #    Sonarr/Radarr/SABnzbd/Plex over MCP with bearer-token auth. It's a
  #    small, single-maintainer project, not something with Nous/Nous-level
  #    scrutiny — read it yourself before trusting it with an API key. Runs
  #    as its own container (see its own docs for the up-to-date deploy
  #    method) exposing an HTTP/SSE MCP endpoint; wire it into
  #    ~/.hermes/config.yaml as a remote MCP server, and use tools.include
  #    to allowlist only the sabnzbd_* tools — the same server can also
  #    restart containers and manage Sonarr/Radarr, which you don't want
  #    exposed just because SABnzbd is the only thing actually running here:
  #
  #      mcp_servers:
  #        sabnzbd:
  #          url: "http://127.0.0.1:<arr-mcp-server's port>"
  #          headers:
  #            Authorization: "Bearer ${ARR_MCP_API_KEY}"   # from ~/.hermes/.env
  #          tools:
  #            include: [ "sabnzbd_*" ]
  # =========================================================================

  # The model backend. Hermes Agent explicitly supports pointing at a local
  # Ollama endpoint ("use any model you want" / `hermes model`) instead of
  # a cloud API — keeps a personal-assistant agent's conversations off
  # third-party infrastructure if that matters to you.
  services.ollama = {
    enable = true;
    acceleration = false; # this box has no GPU worth using — CPU inference only
    listenAddress = "127.0.0.1:11434"; # loopback only; verify option name via `nixos-option services.ollama`
  };
  # Pull a Hermes model once the service is up, e.g.: ollama pull hermes3

  # The installer bundles its own Python/Node binaries rather than using
  # nixpkgs' — those are prebuilt dynamically-linked binaries, which don't
  # run on NixOS without nix-ld (no /lib64/ld-linux-x86-64.so.2 here). This
  # is the same problem modules/dev.nix solves for `uv`-downloaded
  # Pythons; trimmed here to what a Node/Python CLI installer needs,
  # without dev.nix's GUI/ML-oriented X11 and graphics libraries.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      glibc
      zlib
      zstd
      openssl
      curl
      bzip2
      xz
      libxml2
      libxslt
      icu
      expat
      glib
      ncurses
      libffi
    ];
  };

  # Node native addons (better-sqlite3 and friends are common in CLI
  # agents with local persistent memory) commonly need a compiler at
  # install time, even on a machine that never builds anything else.
  environment.systemPackages = with pkgs; [
    gcc
    gnumake
    pkg-config
  ];

  # virtualisation.docker is already enabled in modules/server.nix — that's
  # the same Docker daemon Hermes Agent's `docker` terminal backend talks
  # to; fabian is already in the `docker` group via modules/base.nix.

  # The one directory the agent's sandbox is allowed to touch — matches
  # the docker_volumes entry documented above. Separate from ~/.hermes
  # (the daemon's own config/memory/skills state), which lives on the
  # host and is never bind-mounted into the sandbox container at all.
  systemd.tmpfiles.rules = [
    "d /srv/hermes-agent 0750 fabian fabian -"
    "d /srv/hermes-agent/workspace 0750 fabian fabian -"
  ];

  # Left disabled (not in any target's Wants) until you've actually run
  # the installer above and it's confirmed to exist at this path — a
  # NixOS-managed unit pointing at a binary that isn't there yet would
  # just fail on every boot. Once bootstrapped, add "multi-user.target" to
  # wantedBy (or just `systemctl enable --now hermes-agent`).
  systemd.services.hermes-agent = {
    description = "Hermes Agent gateway (Nous Research)";
    after = [ "network-online.target" "docker.service" "ollama.service" ];
    wants = [ "network-online.target" ];
    environment = {
      # Second, independent confinement layer — see the big comment block
      # above. Not a secret, so this is safe to declare here.
      HERMES_WRITE_SAFE_ROOT = "/srv/hermes-agent/workspace:/home/fabian/.hermes";
      HASS_URL = "http://127.0.0.1:8123";
    };
    serviceConfig = {
      Type = "simple";
      User = "fabian";
      # Path is a guess based on the installer docs (~/.local/bin) — verify
      # with `which hermes` as fabian after running the installer, and fix
      # this if it differs.
      ExecStart = "/home/fabian/.local/bin/hermes gateway";
      # HASS_TOKEN, ARR_MCP_API_KEY, and anything else secret live here —
      # never in this repo. Leading "-" makes it optional, so the unit
      # still starts before you've bootstrapped that file.
      EnvironmentFile = "-/home/fabian/.hermes/.env";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };
}
