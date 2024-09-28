{ config, lib, pkgs, ... }:

# Maybe try sway-nvidia
{
#  boot.kernelParams = [ "nvidia-drm.fbdev=1" ];
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    forceFullCompositionPipeline = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSOR = "1";
  };
}