{ pkgs, username, ... }:

{
  # Deliberately not importing ./default.nix — that one pulls in GNOME
  # theming, a browser, Bitwarden, Slack, Spotify, and a dozen other
  # desktop apps that make no sense on a headless box. Server hosts get
  # the CLI-only subset instead.
  imports = [
    ./shell.nix
    ./git.nix
    ./ssh.nix
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

    mosh # survives SSH sessions across network drops better than raw ssh
  ];

  # tmux matters more here than usual: keep long-running things (a big
  # rsync, a container build) alive across a dropped SSH connection.
  #   ssh servnix -t "tmux new -A -s main"
  programs.tmux = {
    enable = true;
    prefix = "C-a"; # C-b is awkward; C-a is the common swap
    keyMode = "vi";
    mouse = true;
    baseIndex = 1;
    escapeTime = 10;
    historyLimit = 50000;
    terminal = "tmux-256color";

    plugins = with pkgs.tmuxPlugins; [ sensible yank ];

    extraConfig = ''
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      set -g renumber-windows on
      set -g status-position top
    '';
  };
}
