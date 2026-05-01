# Standalone NixOS configuration for bootstrapping NixOS from an ISO
{ config, pkgs, ... }: {
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
    <nixos-hardware/lenovo/thinkpad/x1/12th-gen>
    modules/base.nix
    modules/options.nix
    modules/ssh.nix
  ];

  username = "nixos";
  ssh.preventRootLogin = false; # Root access needed when installing in case there are display issues

  environment = {
    systemPackages = with pkgs; [
      neovim # Basic Neovim for initial editing. Custom version installed later.
      (callPackage ./modules/nixx.nix {})
    ];
  };
}