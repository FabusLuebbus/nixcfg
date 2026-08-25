{ config, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    # Desktop, not a laptop — no battery to protect, so skip the runtime
    # power-management workarounds meant for suspend/resume on mobile GPUs.
    powerManagement.enable = false;
    # Open-source kernel modules. Nvidia's own recommendation on Turing
    # (RTX 20xx) and newer; switch to `open = false` if this card predates
    # Turing or you hit driver issues.
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # CUDA / GPU passthrough into containers (docker run --gpus all, etc).
  nixpkgs.config.cudaSupport = true;
  hardware.nvidia-container-toolkit.enable = true;
}
