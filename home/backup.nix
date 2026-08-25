{ config, lib, pkgs, ... }:

let
  # Mountpoint + hotplug-triggered unlock/mount/backup mechanism live in
  # modules/backup.nix (root-level: LUKS keyfile unlock needs root, and the
  # trigger has to work even when nobody's logged in). This file only
  # declares what the backup should actually do once it runs.
  backupRoot = "/mnt/backup";
  home = config.home.homeDirectory;

  # Bare patterns (no leading slash) match by name at any depth; patterns
  # with a slash are anchored under $HOME. Caches and temp files only —
  # everything else under $HOME gets backed up.
  excludes = [
    # OS / desktop caches
    ".cache"
    ".thumbnails"
    ".local/share/Trash"
    ".var/app/*/cache"
    # editor / shell temp files
    "*.tmp"
    "*~"
    "*.swp"
    "*.bak"
    # dev tool caches — regenerated on demand by uv/npm/cargo/nix-direnv
    ".venv"
    ".direnv"
    "node_modules"
    "__pycache__"
    "target"
    ".npm"
    ".cargo/registry"
    # mountpoint for a remote machine, not local data — never worth backing up
    "${home}/landrive"
  ];

  excludeLines = lib.imap1
    (i: v: "profile1.snapshots.exclude.${toString i}.value=${v}")
    excludes;

  configLines = [
    "config.version=6"
    "profiles=1"
    "profile1.name=Main profile"
    "profile1.snapshots.mode=local"
    "profile1.snapshots.path=${backupRoot}"
    "profile1.snapshots.include.1.type=0"
    "profile1.snapshots.include.1.value=${home}"
  ]
  ++ excludeLines
  ++ [
    # Scheduling is driven by the hotplug-triggered systemd service in
    # modules/backup.nix, not BackInTime's own crontab writer.
    "profile1.schedule.mode=0"
  ];
in
{
  home.packages = [
    pkgs.backintime # GUI, for browsing/restoring snapshots (root-owned
                     # snapshots are readable through its polkit helper)
    pkgs.backintime-common # ships the `backintime` CLI, for manual/debug runs
  ];

  xdg.configFile."backintime/config".text = lib.concatStringsSep "\n" configLines + "\n";
}
