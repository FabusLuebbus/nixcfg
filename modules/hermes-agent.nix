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

  # Left disabled (not in any target's Wants) until you've actually run
  # the installer above and it's confirmed to exist at this path — a
  # NixOS-managed unit pointing at a binary that isn't there yet would
  # just fail on every boot. Once bootstrapped, add "multi-user.target" to
  # wantedBy (or just `systemctl enable --now hermes-agent`).
  systemd.services.hermes-agent = {
    description = "Hermes Agent gateway (Nous Research)";
    after = [ "network-online.target" "docker.service" "ollama.service" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "simple";
      User = "fabian";
      # Path is a guess based on the installer docs (~/.local/bin) — verify
      # with `which hermes` as fabian after running the installer, and fix
      # this if it differs.
      ExecStart = "/home/fabian/.local/bin/hermes gateway";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };
}
