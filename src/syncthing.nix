{ config, pkgs, lib, ... }:

# Setting up a new machine
#   mkdir -p secrets/<machine>
#   syncthing generate --config=secrets/<machine>
# * Grab ID from secrets/<machine>/config.xml and paste here
#   rm secrets/<machine>/config.xml

{
  systemd.tmpfiles.rules = [
    "d ${config.xorg.xdgConfigHome}/syncthing - phil users"
  ];

  services = {
    syncthing = {
      enable = true;
      user = "phil";
      group = "users";
      dataDir = "/data";
      configDir = "/home/phil/.config/syncthing";
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
          "fred" = { id = "EP6BMTU-JTYMWXR-DP3UQQR-2YPBXHX-6F2Y4QM-A2EOUEH-N2SYCR3-RLYM7QB"; };
          "victoria" = { id = "BIU7PKU-XC3UMYZ-EZ736FX-DOPB7CA-ESRG5BB-NO3TCVP-4URAHNF-WHDAXQL"; };
        };
        folders = {
          "Sync" = {                                # Name (and ID) of folder in Syncthing
            path = "/data/sync";                    # Which folder to add to Syncthing
            devices = [ "spruce" "darko" "mev" ];   # Which devices to share the folder with
          };
          "Books" = {
            path = "/data/books";
            devices = [ "spruce" "darko" "mev" ];
          };
          "Documents" = {
            path = "/data/documents";
            devices = [ "spruce" "darko" "mev" ];
          };
          "Music" = {
            path = "/data/music";
            devices = [ "spruce" "darko" "mev" ];
          };
          "Camera" = {
            path = "/data/pictures/camera";
            devices = [ "spruce" "darko" "mev" ];
          };
          "Txt" = {
            path = "/data/txt";
            devices = [ "spruce" "darko" "mev" ];
          };
          "Other" = {
            path = "/data/other";
            devices = [ "spruce" "darko" ];
          };
        };
      };
    };
  };
}