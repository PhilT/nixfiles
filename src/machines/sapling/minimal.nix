# TODO: Ensure no LUKS encryption will be used

{ config, pkgs, ... }: {
  imports = [ ../minimal.nix ];

  networking.hostName = "sapling";

  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    wslConf.interop.appendWindowsPath = false;
    wslConf.network.generateHosts = false;
    defaultUser = config.username;
    startMenuLaunchers = true;
  };
}