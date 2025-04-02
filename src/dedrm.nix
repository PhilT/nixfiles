# Activate Adobe ID account
#   adept_activate

{ config, lib, pkgs, fetchurl, ... }: {
  environment = {
    systemPackages = with pkgs; [
      libgourou                     # Adobe ADEPT DRM protocol
    ];
  };
}