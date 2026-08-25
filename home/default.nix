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
    UV_PYTHON_PREFERENCE = "only-managed"; # uv uses only its own downloaded interpreters, never a python3 off PATH
    NIXPKGS_ALLOW_UNFREE = "1"; # let nix-shell/nix run pull unfree packages without prompting
  };

  home.packages = with pkgs; [
    # CLI
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
    fastfetch # what the `neofetch` alias actually runs

    # Backend for oh-my-zsh's clipcopy on Wayland. Without it the copyfile,
    # copypath and copybuffer plugins fail silently — they detect no
    # clipboard command and just do nothing.
    wl-clipboard

    # Both were standalone curl-installers on the old machine (~/.bun,
    # ~/.opencode/bin) with hand-rolled PATH exports. nixpkgs has both, so
    # they come from here instead and the PATH lines are gone.
    bun
    opencode

    # essential apps
    firefox
    vscode
    # WORKAROUND (2026-08-25): pinned to unstable to escape a broken stable
    # version. 2026.7.0 in nixos-26.05 routes clipboard writes through the XDG
    # portal, which fails because Bitwarden marks its process non-dumpable, so
    # the portal can't read /proc/<pid>/root — copy password silently no-ops.
    # Fixed upstream in 2026.8.0 (bitwarden/clients#22062).
    # REMOVE once nixos-26.05 carries >= 2026.8.0; check with:
    #   nix eval --raw nixpkgs#bitwarden-desktop.version
    # then drop the `unstable.` prefix and this comment.
    # https://github.com/bitwarden/clients/issues/22030
    unstable.bitwarden-desktop
    libreoffice
    backintime
    synology-drive-client
    proton-vpn
    thunderbird
    vlc
    zoom

    # communication
    slack
    discord

    # media
    spotify
    handbrake
    jellyfin-desktop

    # desktop env
    gnome-extension-manager
  ];

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
  # Bitwarden defaults to launching at login and writes this file itself on
  # every start, so the app's own setting only fixes a machine that has already
  # run it once — a fresh install would autostart before we ever got a say.
  # Owning the path is what makes it reproducible: the link points into the
  # read-only store, so Bitwarden's write fails (EROFS, logged and harmless)
  # and Hidden=true keeps GNOME from launching the entry regardless.
  # Turning the setting off in-app as well is what keeps that error out of the
  # log; it is not what makes this stick.
  xdg.configFile."autostart/bitwarden.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Bitwarden
    Hidden=true
  '';

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
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
      ];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "Open Terminal";
      command = "${pkgs.ghostty}/bin/ghostty";
      binding = "<Primary><Alt>t";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      name = "Open File Manager";
      command = "nautilus";
      binding = "<Super>e";
    };
  };
}
