{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./common.nix
    ];

  networking.hostName = "spruce";

  environment.systemPackages = with pkgs; [
  ];
}

