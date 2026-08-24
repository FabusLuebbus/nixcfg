{ pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };
    settings = {
      scrollback_lines = 20000;
      enable_audio_bell = false;
      confirm_os_window_close = 0;
      window_padding_width = 6;
      copy_on_select = "clipboard";
      # kitty's own tabs/splits — handy locally, tmux still wins for remote
      tab_bar_edge = "top";
      tab_bar_style = "powerline";
    };
    keybindings = {
      "ctrl+shift+enter" = "new_window";
      "ctrl+shift+t" = "new_tab";
    };
  };

  # ==========================================================================
  # tmux matters more than usual for you: run it ON THE REMOTE BOX so a
  # dropped VPN or closed laptop never kills a training run. Pattern:
  #     ssh gpu-box -t "tmux new -A -s main"
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
  # worth having when you work on remote machines from a laptop.
  home.packages = [ pkgs.mosh ];
}
