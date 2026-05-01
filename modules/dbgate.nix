{ config, lib, pkgs, fetchurl, ... }: {
  environment = {
    sessionVariables.ELECTRON_OZONE_PLATFORM_HINT = "auto"; # Tells dbgate to use Wayland
    systemPackages = with pkgs; [
      dbgate
      dbeaver-bin                 # Temporary until dbgate is fixed
    ];
  };
}