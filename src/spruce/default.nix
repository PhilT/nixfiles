{ config, pkgs, ... }:

let
  fanatecff = pkgs.linuxPackages.callPackage ../hid-fanatecff/default.nix {};
  steamvr_utils = pkgs.callPackage ../steamvr_utils/default.nix {};
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

  programs.alacritty.fontSize = 12;
  programs.kitty.fontSize = 15;

  services.syncthing.key = "${../../secrets/spruce/syncthing.key.pem}";
  services.syncthing.cert = "${../../secrets/spruce/syncthing.cert.pem}";

  environment.systemPackages = with pkgs; [
    steamvr_utils
  ];

}