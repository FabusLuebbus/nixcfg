{ pkgs, username, ... }:

{
  imports = [
    ./shell.nix
    ./git.nix
    ./ssh.nix
    ./terminal.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  # Same rule as system.stateVersion: set once, never touch again.
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

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

    # editors
    neovim

    # apps
    firefox
    # vscode        # uncomment if you use it
    # slack
    # spotify
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
  };
}
