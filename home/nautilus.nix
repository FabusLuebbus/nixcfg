{ config, ... }:

let
  home = config.home.homeDirectory;

  bookmarks = [
    { path = "${home}/Documents"; label = "Documents"; }
    { path = "${home}/Pictures"; label = "Pictures"; }
    { path = "${home}/Downloads"; label = "Downloads"; }
    { path = "${home}/landrive/fabian/Human"; label = "Landrive-Fabian"; }
    { path = "${home}/landrive/fabian/Human/Uni"; label = "Uni"; }
  ];
in
{
  # Nautilus writes this itself on every bookmark change, so owning the path
  # (like the Bitwarden/Synology autostart entries in default.nix) makes the
  # sidebar reproducible instead of one-off GUI state: the symlink into the
  # read-only store means Nautilus's own writes just fail silently (EROFS),
  # and edits have to go through this file instead.
  xdg.configFile."gtk-3.0/bookmarks".text =
    builtins.concatStringsSep "\n"
      (map (b: "file://${b.path} ${b.label}") bookmarks)
    + "\n";
}
