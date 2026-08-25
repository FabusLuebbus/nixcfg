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
    "profile1.snapshots.include.size=1"
    "profile1.snapshots.include.1.type=0"
    "profile1.snapshots.include.1.value=${home}"
    "profile1.snapshots.exclude.size=${toString (builtins.length excludes)}"
  ]
  ++ excludeLines
  ++ [
    # Scheduling is driven by the hotplug-triggered systemd service in
    # modules/backup.nix, not BackInTime's own crontab writer.
    "profile1.schedule.mode=0"

    # Retention: disk-size-agnostic "fill it up, evict oldest" policy.
    # BackInTime removes the oldest snapshot(s) after each backup until at
    # least this much free space is available again — an absolute margin,
    # not a fraction of disk size, so it needs no per-host tuning.
    #
    # Eviction only runs *after* a backup completes successfully, not
    # before it starts, so this margin has to absorb one full day's worth
    # of new/changed data, not just the long-run average (which is much
    # smaller thanks to hardlink-based incrementals). Too small a margin
    # risks an out-of-space rsync failure on a heavy day — and a failed
    # backup skips eviction too, so it won't self-heal on the next run.
    "profile1.snapshots.min_free_space.enabled=true"
    "profile1.snapshots.min_free_space.value=20"
    "profile1.snapshots.min_free_space.unit=20" # 20 = GB (SizeUnit.GIB)

    # Age-based removal is unset elsewhere; default (10 years) never fires
    # in practice, so min_free_space above is the only real retention knob.
    "profile1.snapshots.remove_old_snapshots.enabled=false"
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
