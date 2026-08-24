{ ... }:

{
  # ==========================================================================
  # Since your real ML work happens on remote machines, this file is the one
  # that decides whether a fresh install "feels like home" in 5 minutes or
  # 5 hours. Declare every box here, once, and it follows you everywhere.
  #
  # NOTE: this generates ~/.ssh/config. Your PRIVATE KEYS are not managed
  # here — restore those from backup, or later move to sops-nix/agenix.
  # ==========================================================================

  programs.ssh = {
    enable = true;

    # If a rebuild warns about `enableDefaultConfig`, set it to false and
    # move the global options below into a matchBlocks."*" entry instead.
    # enableDefaultConfig = false;

    matchBlocks = {
      # ---------------------------------------------------------- templates
      # Copy-paste and rename one of these per remote machine.

      "gpu-box" = {
        hostname = "CHANGEME.example.com";
        user = "CHANGEME";
        identityFile = "~/.ssh/id_ed25519";
        forwardAgent = true; # lets you git-clone on the remote with local keys
        serverAliveInterval = 60;
        serverAliveCountMax = 3;

        # Connection multiplexing — second and later connections to the same
        # host are instant. Big deal when an editor opens several at once.
        controlMaster = "auto";
        controlPath = "~/.ssh/sockets/%r@%h:%p";
        controlPersist = "10m";

        # Forward a Jupyter/TensorBoard port automatically on connect:
        # localForwards = [
        #   { bind.port = 8888; host.address = "localhost"; host.port = 8888; }
        #   { bind.port = 6006; host.address = "localhost"; host.port = 6006; }
        # ];
      };

      # A box only reachable through a bastion/jump host.
      "cluster-node" = {
        hostname = "CHANGEME-internal";
        user = "CHANGEME";
        proxyJump = "jump";
        identityFile = "~/.ssh/id_ed25519";
        forwardAgent = true;
      };

      "jump" = {
        hostname = "CHANGEME-bastion.example.com";
        user = "CHANGEME";
        identityFile = "~/.ssh/id_ed25519";
      };

      # ------------------------------------------------------------ forges
      "github.com" = {
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
      };

      "gitlab.com" = {
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };

  # controlPath needs its directory to exist.
  home.file.".ssh/sockets/.keep".text = "";

  # Agent that caches your key passphrase for the session.
  services.ssh-agent.enable = true;
}
