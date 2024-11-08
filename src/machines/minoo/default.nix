# Copy of Sirius config, tweaked to work with the Lenovo X1 Carbon.

{ config, lib, pkgs, ... }: {
  imports = [
    <catppuccin/modules/nixos>

    ./machine.nix
    ../../hardware/default.nix
    ../../hardware/bluetooth.nix
    ../../minimal-configuration.nix
    ../../common.nix
    ../../common_gui.nix

    # Sync
    # Not only does this provide a sync command to my phone but also
    # makes the unison command available for other machines to use.
    ../../unison/suuno.nix
    ../../ssh.nix

    # Media Server/Player
    ./kodi_module.nix
    ./kodi.nix

    # Desktop
    ../../desktop/default.nix
    ../../desktop/light.nix
  ];

  # How do we supply the key?
  # Need to change to keyfile instead of prompt?
  # Maybe not though, if permanently on and connected to the TV that
  # might enough to keep simple password login.

  hardware.graphics.enable = true; # TODO: Move into generic config
}