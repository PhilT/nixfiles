# Imported by iso.nix and minimal.nix
{ config, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    curl
    gcc
    git
    gnumake
    htop
    libyaml
    lsof
    pkg-config
    ruby_3_4
    wget
    which
  ];
}