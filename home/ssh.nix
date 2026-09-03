_: {
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

    # Old default config values, now made explicit since enableDefaultConfig
    # will lose its defaults in a future home-manager release.
    enableDefaultConfig = false;

    settings = {
      "*" = {
        ForwardAgent = false;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };

      # ---------------------------------------------------------- templates
      # Copy-paste and rename one of these per remote machine.

      #      "gpu-box" = {
      #        HostName = "CHANGEME.example.com";
      #        User = "CHANGEME";
      #        IdentityFile = "~/.ssh/id_ed25519";
      #        ForwardAgent = true; # lets you git-clone on the remote with local keys
      #        ServerAliveInterval = 60;
      #        ServerAliveCountMax = 3;
      #
      #        # Connection multiplexing — second and later connections to the same
      #        # host are instant. Big deal when an editor opens several at once.
      #        ControlMaster = "auto";
      #        ControlPath = "~/.ssh/sockets/%r@%h:%p";
      #        ControlPersist = "10m";
      #
      # Forward a Jupyter/TensorBoard port automatically on connect:
      # LocalForward = [
      #   { bind.port = 8888; host.address = "localhost"; host.port = 8888; }
      #   { bind.port = 6006; host.address = "localhost"; host.port = 6006; }
      # ];
      #      };

      # A box only reachable through a bastion/jump host.
      #      "cluster-node" = {
      #        HostName = "CHANGEME-internal";
      #        User = "CHANGEME";
      #        ProxyJump = "jump";
      #        IdentityFile = "~/.ssh/id_ed25519";
      #        ForwardAgent = true;
      #      };
      #
      #      "jump" = {
      #        HostName = "CHANGEME-bastion.example.com";
      #        User = "CHANGEME";
      #        IdentityFile = "~/.ssh/id_ed25519";
      #      };

      # ------------------------------------------------------------ forges
      "github.com" = {
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
      };

      "gitlab.com" = {
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
      };

      "horeka" = {
        HostName = "horeka.scc.kit.edu";
        User = "co7453";
        IdentityFile = "~/.ssh/id_ed25519";
      };
    };
  };

  # controlPath needs its directory to exist.
  home.file.".ssh/sockets/.keep".text = "";

  # Agent that caches your key passphrase for the session.
  services.ssh-agent.enable = true;
}
