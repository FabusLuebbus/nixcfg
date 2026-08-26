{ pkgs, ... }:

{
  # ==========================================================================
  # tmux matters more than usual for you: run it ON THE REMOTE BOX so a
  # dropped VPN, a closed laptop, or a reboot never kills a long-running
  # session. Pattern:
  #     ssh gpu-box -t "tmux new -A -s main"
  # Shared between desktop and server home profiles — nothing here is
  # GUI-specific.
  # ==========================================================================
  programs.tmux = {
    enable = true;
    prefix = "C-a"; # C-b is awkward; C-a is the common swap
    keyMode = "vi";
    mouse = true;
    baseIndex = 1;
    escapeTime = 10;
    historyLimit = 50000;
    terminal = "tmux-256color";

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      {
        plugin = resurrect;
        extraConfig = "set -g @resurrect-strategy-nvim 'session'";
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '10'
        '';
      }
    ];

    extraConfig = ''
      # more intuitive splits
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # vim-style pane movement
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      bind r source-file ~/.config/tmux/tmux.conf \; display "reloaded"

      set -g renumber-windows on
      set -g status-position top
    '';
  };

  # mosh survives suspend and network changes far better than raw ssh —
  # worth having when you work on remote machines from a laptop, and
  # equally worth having when the remote machine IS the laptop.
  home.packages = [ pkgs.mosh ];
}
