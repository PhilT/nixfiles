{ config, lib, pkgs, ... }: {
  imports = [
    ./machine.nix
    ../../minimal-configuration.nix
    ../../hardware/default.nix
    ../../hardware/filesystems.nix
    ../../hardware/bluetooth.nix
    ../../common.nix
    ../../development.nix

    # Sync
    # ?

    # Desktop
    ../../desktop/default.nix
    ../../desktop/light.nix
  ];

  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    wslConf.interop.appendWindowsPath = false;
    wslConf.network.generateHosts = false;
    defaultUser = config.username;
    startMenuLaunchers = true;
  };
}