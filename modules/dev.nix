{pkgs, ...}: {
  # ==========================================================================
  # nix-ld — THE most important block in this whole repo for your workflow.
  #
  # NixOS has no /lib64/ld-linux-x86-64.so.2, so any prebuilt dynamically
  # linked binary refuses to even start. That includes:
  #   - the CPython builds `uv python install` downloads
  #   - manylinux wheels (numpy, scipy, torch, polars, pyarrow, ...)
  #   - random vendor binaries and .deb payloads
  #
  # nix-ld provides a shim loader plus the libraries listed below. With this
  # in place, `uv` behaves essentially the way it does on Ubuntu.
  #
  # If something still fails at runtime, the error names the missing .so —
  # find the nixpkgs package that provides it, add it here, rebuild.
  # ==========================================================================
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # core C/C++ runtime — covers the overwhelming majority of failures
      stdenv.cc.cc.lib
      glibc
      zlib
      zstd
      openssl
      curl

      # compression / parsing, pulled in by many scientific wheels
      bzip2
      xz
      libxml2
      libxslt
      icu
      expat

      # glib family — pandas plotting, opencv, anything GUI-adjacent
      glib

      # graphics — matplotlib backends, opencv, torch's viz extras
      libGL
      libGLU
      freetype
      fontconfig

      # X libs — needed by opencv-python and various plotting backends
      libx11
      libxext
      libxrender
      libxi
      libxrandr
      libsm
      libice
      libxcb

      # occasionally required by ML tooling talking to remote clusters
      libffi
      ncurses
    ];
  };

  # ---------------------------------------------------------------- containers
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    autoPrune.dates = "weekly";
  };

  # =========================================================================
  # Your escape hatch. When something insists on being on Ubuntu:
  #   distrobox create --name ubuntu --image ubuntu:24.04
  #   distrobox enter ubuntu
  # Your $HOME is mounted inside. Binaries can be exported to the host PATH.
  # House rule: if a package fight passes 30 minutes, it goes in here.
  # =========================================================================

  environment.systemPackages = with pkgs; [
    # containers
    distrobox
    docker-compose

    # python / ml tooling — uv manages project envs, these are the system floor
    uv
    ruff

    # build essentials, for anything that compiles at install time
    gcc
    gnumake
    cmake
    pkg-config
    linuxHeaders

    # remote work — where your actual ML happens
    openssh
    mosh
    rsync
    sshfs
  ];

  # NixOS has no /usr/include, so <linux/input.h> and friends (needed to
  # build packages like evdev, which ships source-only on PyPI) aren't found
  # by default. Point the compiler at nixpkgs' copy globally.
  environment.variables.C_INCLUDE_PATH = "${pkgs.linuxHeaders}/include";

  # Larger inotify limits — language servers and file watchers hit the
  # default ceiling on big repos.
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 512;
  };
}
