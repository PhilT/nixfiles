{ config, pkgs, ... }:

{
  imports =
    [
      ./spruce-minimal.nix
      ./common.nix
      ./nvidia.nix
    ];

  services.syncthing.key = "../secrets/spruce/syncthing.key.pem";
  services.syncthing.cert = "../secrets/spruce/syncthing.cert.pem";

  environment.systemPackages = with pkgs; [
  ];
}

