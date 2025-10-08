{ config, lib, pkgs, ... }: {
  boot.kernelParams = [ "nvidia-drm.modeset=1" ];

  boot.blacklistedKernelModules = [ "i915" "nouveau" ];

  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    #forceFullCompositionPipeline = true;
    open = false;
    nvidiaSettings = true;
    #package = config.boot.kernelPackages.nvidiaPackages.beta;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSOR = "1";
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  environment.systemPackages = with pkgs; [
    vulkan-tools  # does not include vkcube any more
    furmark       # for testing

    (writeShellScriptBin "vk-fur" ''
      furmark --demo furmark-vk --vsync 60
    '')
  ];

}