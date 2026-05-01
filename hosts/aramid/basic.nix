# Cut down version of default.nix to sway to build
# default.nix was causing kernel panic on Aramid.
# This tries to stage the packages a bit more.
# TODO: Once we reinstall Aramid with default.nix
#       we can remove this configuration.

{ config, lib, pkgs, ... }: {
  imports = [
    <nixos-hardware/lenovo/thinkpad/x1/12th-gen>
    <catppuccin/modules/nixos>

    ./machine.nix
    ../../modules/hardware/default.nix
    ../../modules/hardware/filesystems.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/minimal.nix
    ../../modules/common.nix

    # Windowing
    ../../modules/sway/default.nix
  ];

  environment.systemPackages = with pkgs; [
    kitty
  ];
}