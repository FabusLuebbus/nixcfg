{ pkgs, username, ... }:

{
  # Deliberately not importing ./default.nix — that one pulls in GNOME
  # theming, a browser, Bitwarden, Slack, Spotify, and a dozen other
  # desktop apps that make no sense on a headless box. Everything else —
  # the full zsh/oh-my-zsh/atuin/fzf setup, git+delta+lazygit, tmux with
  # session persistence, Claude Code — carries over unchanged, so the CLI
  # experience here is identical to the desktop hosts.
  imports = [
    ./shell.nix
    ./git.nix
    ./ssh.nix
    ./tmux.nix
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
  ];
}
