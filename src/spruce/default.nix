{ config, pkgs, ... }:

let
  fanatecff = config.boot.kernelPackages.callPackage ../hid-fanatecff/default.nix {};
in
{
  imports = [
    ./minimal.nix
    ./power.nix

    ../gaming.nix
    ../phil.nix
    ../nvidia.nix
  ];

  boot.extraModulePackages = [ fanatecff ];
  services.udev.packages = [ fanatecff ];
  boot.kernelModules = [ "hid-fanatec" ];

  programs.kitty.fontSize = 15;

  services.syncthing.key = "${../../secrets/spruce/syncthing.key.pem}";
  services.syncthing.cert = "${../../secrets/spruce/syncthing.cert.pem}";

  services.xserver.displayManager.setupCommands = ''
    LEFT='DP-2'
    RIGHT='DP-4'
    ${pkgs.xorg.xrandr}/bin/xrandr --output $LEFT --left-of $RIGHT --output $RIGHT
  '';
}