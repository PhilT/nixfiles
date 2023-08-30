{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./common.nix
      ./nvidia.nix
    ];

  networking.hostName = "spruce";

  environment.systemPackages = with pkgs; [
  ];
}

