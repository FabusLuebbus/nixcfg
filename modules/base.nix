{ pkgs, username, inputs, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      unstable = import inputs.nixpkgs-unstable {
        system = prev.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
    })
  ];

  # ---------------------------------------------------------------- nix itself
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    # Extra binary caches. Add cuda-maintainers here IF you ever build CUDA
    # things locally — without it you compile PyTorch from source for hours.
    substituters = [
      "https://cache.nixos.org"
      # "https://cuda-maintainers.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      # "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };

  # The store grows fast. Set this on day one, not after you fill a disk.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nixpkgs.config.allowUnfree = true;

  # ------------------------------------------------------------ locale / time
  time.timeZone = "Europe/Berlin";

  # English interface, German formats for dates/paper/units.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
  };

  console.keyMap = "de";

  # ------------------------------------------------------------------- users
  users.users.${username} = {
    isNormalUser = true;
    description = "";
    extraGroups = [
      "wheel" # sudo
      "networkmanager"
      "docker"
      "video"
      "audio"
    ];
    shell = pkgs.zsh;
  };

  # Required for zsh to work as a login shell — home-manager alone is not
  # enough, the shell must also be registered system-wide.
  programs.zsh.enable = true;

  # ---------------------------------------------------------------- networking
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  # ------------------------------------------------------------------ packages
  # Keep this list minimal. Almost everything belongs in home/ instead.
  # Rule of thumb: system packages are things needed to REPAIR a broken system.
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    pciutils
    usbutils
  ];

  # --------------------------------------------------------------------- fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
  ];

  # ------------------------------------------------------------------- misc QoL
  services.fwupd.enable = true; # firmware updates
  hardware.enableRedistributableFirmware = true;

  # Uncomment if you want to SSH *into* this machine.
  # services.openssh = {
  #   enable = true;
  #   settings.PasswordAuthentication = false;
  # };
}
