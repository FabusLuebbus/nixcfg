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

  # No home-manager module for ghostty yet (as of home-manager 26.05), so
  # it's just a package + the plain config file above — same pattern as the
  # "bringing existing dotfiles" note in home/default.nix.
  #
  # tmux/mosh live in ./tmux.nix instead of here — this file is only the
  # GUI terminal emulator, so headless hosts can skip it.
  home.packages = [ pkgs.ghostty ];
}
