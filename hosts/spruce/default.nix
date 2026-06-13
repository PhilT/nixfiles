{ config, lib, pkgs, ... }: {
  imports = [
    ./minimal.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/plymouth.nix
    ../../modules/common.nix
    ../../modules/common_gui.nix
    ../../modules/development.nix
    ../../modules/studio.nix
    ../../modules/gaming.nix

    # Sync
    ../../modules/ssh.nix
    ../../modules/unison/minoo.nix

    # Windowing
    ../../modules/sway/mako.nix
    ../../modules/sway/tofi.nix
    ../../modules/sway/waybar.nix
    ../../modules/sway/default.nix

    # Desktop
    ../../modules/desktop/light.nix
  ];

  waybarModules = [
    "pulseaudio"
    "network"
    "cpu"
    "memory"
    "disk"
    "temperature"
    "bluetooth"
    "sway/language"
    "clock"
    "tray"
  ];

  # This appears to use quite a lot of resources
  # RGB software is also known to cause reprojection issues
  # and could be interferring with my Gaming setup
  # services.hardware.openrgb.enable = true;

  hardware.graphics.enable = true;

  # Support for Ploopy trackball (and supposedly GMMK 2 but isn't currently working)
  hardware.keyboard.qmk.enable = true;

  # Plymouth UI is a bit small without this
  boot.plymouth.extraConfig = "DeviceScale=2";

  # Defensive: disable Wake-on-LAN on the wired NIC so the desktop doesn't
  # come back to life unattended for stray magic packets.
  systemd.services.disable-wol-enp5s0 = {
    description = "Disable Wake-on-LAN on enp5s0";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.ethtool}/bin/ethtool -s enp5s0 wol d";
    };
  };

  environment.shellAliases = {
    sprucet = "tmux -S /tmp/tmux-1000/shared new -A -s main";
  };
}