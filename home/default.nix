{ pkgs, username, ... }:

{
  imports = [
    ./shell.nix
    ./git.nix
    ./ssh.nix
    ./terminal.nix
    ./claude-code.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  # Same rule as system.stateVersion: set once, never touch again.
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  home.sessionVariables = {
    UV_PYTHON_PREFERENCE = "only-managed";
    NIXPKGS_ALLOW_UNFREE = "1";
  };

  home.packages = with pkgs; [
    # modern CLI
    ripgrep
    fd
    bat
    eza
    sd
    jq
    yq-go
    htop
    btop
    tree
    dust
    duf
    unzip
    p7zip

    # apps
    firefox
    vscode
    slack
    spotify
    discord
    bitwarden-desktop
    libreoffice

    #desktop env
    gnome-extension-manager
  ];

  # direnv + nix-direnv gives you per-project environments that activate on
  # `cd`. Pairs well with uv: a two-line .envrc per repo and your venv,
  # env vars and tool versions load automatically.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };

  # ---- Bringing existing dotfiles across -----------------------------------
  # Do NOT rewrite your Neovim config in Nix. Point at the real files:
  #
  #   home.file.".config/nvim" = {
  #     source = ../dotfiles/nvim;
  #     recursive = true;
  #   };
  #
  # Use `mkOutOfStoreSymlink` instead if you want to keep editing it live:
  #
  #   home.file.".config/nvim".source =
  #     config.lib.file.mkOutOfStoreSymlink "/home/${username}/nixcfg/dotfiles/nvim";
  # --------------------------------------------------------------------------

  programs.gnome-shell = {
    enable = true;
    extensions = [ ];
  };
  # GNOME settings, declared. Fill in more once you know what you want —
  # `dconf watch /` in a terminal shows you the key for anything you change
  # in the GUI, which you can then paste in here.
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
    "org/gnome/desktop/peripherals/touchpad" = {
      natural-scroll = true;
      tap-to-click = true;
    };
    # GNOME dropped the old built-in "terminal" media-key binding, so a
    # custom keybinding pointing at an explicit command is the only way
    # to do this declaratively.
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      ];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "Open Terminal";
      command = "${pkgs.ghostty}/bin/ghostty";
      binding = "<Primary><Alt>t";
    };
  };
}
