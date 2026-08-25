{ config, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    # Needed for suspend/hibernate to actually restore the GPU afterwards —
    # without it, resume leaves nvidia-drm unable to re-init the display
    # (atomic modeset/flip-event-timeout errors) and the box never reaches
    # the login screen again, forcing a hard power-cycle. Not laptop-only:
    # that's powerManagement.finegrained (PRIME/RTD3), a different option.
    powerManagement.enable = true;
    # Open-source kernel modules. Nvidia's own recommendation on Turing
    # (RTX 20xx) and newer; switch to `open = false` if this card predates
    # Turing or you hit driver issues.
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # GPU passthrough into containers (docker run --gpus all, etc). Containers
  # bring their own CUDA runtime, so this only needs the driver above — it
  # does NOT need nixpkgs.config.cudaSupport.
  hardware.nvidia-container-toolkit.enable = true;

  # Deliberately NOT setting nixpkgs.config.cudaSupport = true here. That
  # flag makes Nix build CUDA-enabled variants of anything in nixpkgs that
  # offers one (opencv, ffmpeg-full, ...) from source — on desknix that
  # cascaded into a multi-hour opencv+CUDA compile that OOM'd the machine
  # before it was even 10% done, because the cuda-maintainers cachix cache
  # mostly targets nixpkgs-unstable, not the nixos-26.05 pin this repo uses.
  # Nothing here needs it: PyTorch et al. come from `uv`-managed prebuilt
  # wheels (see modules/dev.nix's nix-ld block), which bundle their own CUDA
  # libs and only need the driver, not a Nix-built CUDA toolchain. If a
  # future package genuinely needs a Nix-built CUDA variant, scope it to
  # that one derivation (an overlay + pkgs.cudaPackages) instead of flipping
  # this global switch again.
}
