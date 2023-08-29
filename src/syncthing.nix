{ config, pkgs, ... }:

{
  services = {
    syncthing = {
      enable = true;
      user = "phil";
      dataDir = "/home/phil";
      overrideDevices = true; # Removes devices from Syncthing that are not configured here
      overrideFolders = true; # Removes folders from Syncthing that are not configured here
      settings = {
        options = {
          localAnnouceEnabled = false;
          urAccepted = -1;
        };
        gui.theme = "black";
        devices = {
          "spruce" = { id = "Y5VVR77-QCSCSU3-QWOXSVW-V4E75O4-BJ4DFC7-VWYVEMI-CSOAB24-6HYWCAK"; };
          "darko" = { id = "IJ6Z7AG-JESH6MF-DNUNQ7H-5C7ZESQ-DC6QK33-VCTNOQR-7S2KYGH-XTQBFAV"; };
          "mev" = { id = "F5SBWVX-KKGBIFU-IE3KFNO-BUFJQXT-Y7S3YME-OOKUHGG-BZRCSUX-PIR4HAS"; };
        };
        folders = {
          "Sync" = {                                # Name (and ID) of folder in Syncthing
            path = "/data/sync";                    # Which folder to add to Syncthing
            devices = [ "spruce" "darko" "mev" ];   # Which devices to share the folder with
            copyOwnershipFromParent = true;
          };
          "Music" = {
            path = "/data/music";
            devices = [ "spruce" "darko" "mev" ];
            copyOwnershipFromParent = true;
          };
          "Camera" = {
            path = "/data/pictures/camera";
            devices = [ "spruce" "darko" "mev" ];
            copyOwnershipFromParent = true;
          };
          "Txt" = {
            path = "/data/txt";
            devices = [ "spruce" "darko" "mev" ];
            copyOwnershipFromParent = true;
          };
        };
      };
    };
  };
}
