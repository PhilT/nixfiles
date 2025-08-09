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
    ../../hardware/default.nix
    ../../hardware/filesystems.nix
    ../../hardware/bluetooth.nix
    ../../minimal.nix
    ../../common.nix

    # Windowing
    ../../sway/default.nix
  ];

  environment.systemPackages = with pkgs; [
    kitty
  ];
}