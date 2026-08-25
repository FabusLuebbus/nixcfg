{ pkgs, lib, username, ... }:

{
  imports = [
    ./shell.nix
    ./git.nix
    ./ssh.nix
    ./terminal.nix
    ./claude-code.nix
    ./backup.nix
    ./gnome-extensions.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  # Same rule as system.stateVersion: set once, never touch again.
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  # GNOME dropped shipping an actual "Adwaita-dark" theme years ago (dark mode
  # is now the gtk-application-prefer-dark-theme boolean instead), so legacy
  # GTK3 widgets that still look up a literal dark theme *name* (e.g.
  # Electron's native menu bar) need a real theme package to point at.
  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
  };

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
    fastfetch

    # util
    wl-clipboard
    openvpn
    proton-vpn
    solaar
    synology-drive-client
    xdotool

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
    thunderbird
    vlc
    papers

    # communication
    slack
    discord
    zoom
    telegram-desktop

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

  # programs.gnome-shell is configured in ./gnome-extensions.nix.

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
      # color-scheme alone only tells theme-aware apps (libadwaita, Bitwarden's
      # own content) to pick their dark variant. Server-side window
      # decorations that Wayland/libdecor draws for apps without CSD (e.g.
      # Electron's title bar/border) come from the legacy gtk-theme key
      # instead — without this it stays light even with color-scheme set.
      gtk-theme = "adw-gtk3-dark";
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
    "org/gnome/shell/extensions/tilingshell" = {
      # inner-gaps/outer-gaps are uint32 (type "u") in tilingshell's schema;
      # a plain int here writes as int32, which GSettings treats as a type
      # mismatch and silently falls back to the schema defaults (16/8).
      inner-gaps = lib.hm.gvariant.mkUint32 4;
      outer-gaps = lib.hm.gvariant.mkUint32 2;
      span-window-all-tiles = [ "<Control><Super>space" ];
      span-window-down = [ "<Control><Super>Down" ];
      span-window-left = [ "<Control><Super>Left" ];
      span-window-right = [ "<Control><Super>Right" ];
      span-window-up = [ "<Control><Super>Up" ];
      edge-tiling-mode = "default";
      enable-window-border = false;
      show-indicator = false;
      window-use-custom-border-color = false;
      # The custom 4-tile layout definition (available to pick per-monitor).
      layouts-json = builtins.toJSON [
        {
          id = "6183749";
          tiles = [
            {
              x = 0;
              y = 0;
              width = 0.5;
              height = 0.5;
              groups = [
                1
                2
              ];
            }
            {
              x = 0.5;
              y = 0;
              width = 0.49999999999999994;
              height = 0.5;
              groups = [
                3
                1
              ];
            }
            {
              x = 0;
              y = 0.5;
              width = 0.5;
              height = 0.5;
              groups = [
                2
                1
              ];
            }
            {
              x = 0.5;
              y = 0.5;
              width = 0.49999999999999994;
              height = 0.5;
              groups = [
                3
                1
              ];
            }
          ];
        }
      ];
      # selected-layouts is deliberately NOT pinned here: it's a per-monitor
      # assignment ([['6183749'], ['6183749']] on framenix's single monitor),
      # not a portable setting. desknix has more monitors, so a fixed-length
      # array here would misassign layouts or leave extra monitors on
      # tilingshell's default. Pick the layout per-monitor in the UI instead.
      # tilingshell's own record of the keybindings/mutter settings it
      # overrides on startup; harmless since we don't set those keys
      # ourselves anywhere else.
      overridden-settings = builtins.toJSON {
        "org.gnome.mutter.keybindings" = {
          toggle-tiled-right = "['<Super>Right']";
          toggle-tiled-left = "['<Super>Left']";
        };
        "org.gnome.desktop.wm.keybindings" = {
          maximize = "['<Super>Up']";
          unmaximize = "['<Super>Down', '<Alt>F5']";
        };
        "org.gnome.mutter" = {
          edge-tiling = "true";
        };
      };
    };
    # ArcMenu's search box corner radius toggle+value; a (bool, int) gvariant tuple.
    "org/gnome/shell/extensions/arcmenu" = {
      search-entry-border-radius = lib.hm.gvariant.mkTuple [
        true
        25
      ];
    };
    "org/gnome/shell/extensions/caffeine" = {
      indicator-position-max = 2;
    };
    # Only the layout/ordering prefs; skip the "profiles" blob (an internal
    # snapshot, not user-editable) and storage-main (a disk device name,
    # specific to this laptop's internal NVMe).
    "org/gnome/shell/extensions/astra-monitor" = {
      gpu-indicators-order = [
        "icon"
        "activity bar"
        "activity graph"
        "activity percentage"
        "memory bar"
        "memory graph"
        "memory percentage"
        "memory value"
      ];
      memory-indicators-order = [
        "icon"
        "bar"
        "graph"
        "percentage"
        "value"
        "free"
      ];
      monitors-order = [
        "processor"
        "gpu"
        "memory"
        "storage"
        "network"
        "sensors"
      ];
      network-indicators-order = [
        "icon"
        "IO bar"
        "IO graph"
        "IO speed"
      ];
      processor-indicators-order = [
        "icon"
        "bar"
        "graph"
        "percentage"
        "frequency"
      ];
      sensors-indicators-order = [
        "icon"
        "value"
      ];
      storage-indicators-order = [
        "icon"
        "bar"
        "percentage"
        "value"
        "free"
        "IO bar"
        "IO graph"
        "IO speed"
      ];
      storage-header-graph = true;
      storage-header-io-bars = false;
      storage-header-tooltip-value = false;
    };
  };
}
