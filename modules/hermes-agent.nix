{ ... }:

{
  # =========================================================================
  # Hermes agent sandbox
  #
  # Split into two pieces on purpose:
  #   - Model inference (ollama, serving a Nous Hermes GGUF model) is plain
  #     text generation with no tool/file/network access of its own — no
  #     reason to sandbox it, so it runs as an ordinary trusted NixOS
  #     service. nixpkgs ships a native module for it; no Docker overhead.
  #   - The AGENT — the part that calls tools, browses the web, and touches
  #     files on your behalf — is the part with a real blast radius, so
  #     that one runs in Docker. The container boundary IS the sandbox:
  #     inside it the agent gets ordinary full access (this is deliberately
  #     NOT a --privileged or capability-locked-down container — the point
  #     is unrestricted access to its OWN filesystem/process space, walled
  #     off from the rest of this machine, not a further-restricted agent).
  #
  # Network: the container uses host networking (see extraOptions below),
  # so it gets the same outbound internet access as the host itself —
  # needed for the "web access" part of a personal-assistant agent. That
  # also means it is NOT network-segmented from your LAN the way a bridge
  # network would isolate it; if that matters later, switch to a
  # user-defined bridge network and publish only the ports you need.
  # =========================================================================

  services.ollama = {
    enable = true;
    # This box has no GPU worth using — CPU inference only. Flip to "cuda"
    # /"rocm" if servnix ever gets a real GPU.
    acceleration = false;
    # Loopback only: reachable from the agent container (shared network
    # namespace, see below) and from you over SSH, never off the box
    # directly. NOTE: verify this option name (`listenAddress`) against
    # `nixos-option services.ollama` before your first switch — this repo
    # has no working Nix installation to dry-build against right now.
    listenAddress = "127.0.0.1:11434";
  };
  # Pull a Hermes model once the service is up, e.g.:
  #   ollama pull hermes3

  # Workspace the agent container can read/write freely. Deliberately NOT
  # $HOME, NOT the Docker socket, NOT /mnt/backup — only this one
  # directory is exposed to it.
  systemd.tmpfiles.rules = [
    "d /srv/hermes-agent 0750 fabian fabian -"
  ];

  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers.hermes-agent = {
    # Placeholder — swap in whatever agent image/build you land on
    # (a Dockerfile you build yourself, or an existing agent framework
    # pointed at the local ollama API below).
    # image = "ghcr.io/CHANGEME/hermes-agent:latest";

    # Off until `image` above is real — an unbuildable/missing image would
    # otherwise fail the whole `nixos-rebuild switch`, not just this
    # container.
    autoStart = false;

    environment = {
      OLLAMA_BASE_URL = "http://127.0.0.1:11434";
    };
    volumes = [
      "/srv/hermes-agent:/workspace"
    ];
    extraOptions = [
      "--network=host"
    ];
  };
}
