{ config, lib, pkgs, ... }: {
  boot.kernelModules = [
    "nvidia"
    "nvidia_uvm"
    "nvidia_modeset"
    "nvidia_drm"
  ];

  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    #forceFullCompositionPipeline = true;
    open = false;
    nvidiaSettings = true;
    #package = config.boot.kernelPackages.nvidiaPackages.beta;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSOR = "1";
  };

  environment.systemPackages = with pkgs; [
    vulkan-tools  # does not include vkcube any more
    furmark       # for testing

    (writeShellScriptBin "vk-fur" ''
      furmark --demo furmark-vk --vsync 60
    '')
  ];

}