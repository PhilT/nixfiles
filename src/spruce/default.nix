{ config, pkgs, ... }:

{
  imports = [
    ./minimal.nix

    ../gaming.nix
    ../phil.nix
    ../nvidia.nix
  ];

  boot.extraModulePackages = [  ];
  services.udev.packages = [  ];
  boot.kernelModules = [  ];

  programs.kitty.fontSize = 15;

  services.syncthing.key = "${../../secrets/spruce/syncthing.key.pem}";
  services.syncthing.cert = "${../../secrets/spruce/syncthing.cert.pem}";

  # TODO: Need to move to Spruce specific hyprland.conf
  services.xserver.displayManager.setupCommands = ''
    LEFT='DP-2'
    RIGHT='DP-4'
    ${pkgs.xorg.xrandr}/bin/xrandr --output $LEFT --left-of $RIGHT --output $RIGHT
  '';
}