{ config, lib, pkgs, ... }:

{
  boot.kernelModules = [ "nouveau" ];

  services.xserver.videoDrivers = ["nouveau"];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      mesa
      mesa.drivers
    ];
  };
}