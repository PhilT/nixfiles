# Standalone NixOS configuration for bootstrapping NixOS from an ISO
{ config, pkgs, ... }: {
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
    <nixos-hardware/lenovo/thinkpad/x1/12th-gen>
    src/base.nix
    src/options.nix
    src/ssh.nix
  ];

  username = "nixos";
  ssh.preventRootLogin = false; # Root access needed when installing in case there are display issues

  environment.systemPackages = with pkgs; [
    neovim

    (callPackage ./src/nixx.nix {})
  ];
}