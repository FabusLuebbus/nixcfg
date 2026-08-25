{ pkgs, ... }:

{
  xdg.configFile."ghostty/config".text = ''
    font-family = JetBrainsMono Nerd Font
    font-size = 12
    window-padding-x = 6
    window-padding-y = 6
    scrollback-limit = 100000000
    copy-on-select = clipboard
    confirm-close-surface = false

    keybind = ctrl+shift+enter=new_window
    keybind = ctrl+shift+t=new_tab
  '';

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
  #
  # No home-manager module for ghostty yet (as of home-manager 26.05), so
  # it's just a package + the plain config file above — same pattern as the
  # "bringing existing dotfiles" note in home/default.nix.
  home.packages = [ pkgs.mosh pkgs.ghostty ];
}
