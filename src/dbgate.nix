{ config, lib, pkgs, fetchurl, ... }: {
  environment = {
    sessionVariables.ELECTRON_OZONE_PLATFORM_HINT = "auto"; # Tells dbgate to use Wayland
    systemPackages = [ pkgs.dbgate ];
  };
}