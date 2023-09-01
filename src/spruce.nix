{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./common.nix
      ./nvidia.nix
    ];

  networking.hostName = "spruce";

  services.syncthing.key = "./spruce/syncthing.key.pem";
  services.syncthing.cert = "./spruce/syncthing.cert.pem";

  environment.systemPackages = with pkgs; [
  ];
}

