{ config, pkgs, lib, ... }:

# Setting up a new machine
#   mkdir -p secrets/<machine>
#   syncthing generate --config=secrets/<machine>
# * Grab ID displayed and paste below
#   rm secrets/<machine>/config.xml

{
  systemd.tmpfiles.rules = [
    "d ${config.xdgConfigHome}/syncthing - phil users"
  ];

  services = {
    syncthing = {
      enable = true;
      user = "phil";
      group = "users";
      dataDir = "/data";
      configDir = "${config.xdgConfigHome}/syncthing";
      overrideDevices = true; # Removes devices from Syncthing that are not configured here
      overrideFolders = true; # Removes folders from Syncthing that are not configured here
      settings = {
        options = {
          localAnnouceEnabled = false;
          urAccepted = -1;
        };
        gui.theme = "black";
        devices = {
          "spruce" = { id = "Y5VVR77-QCSCSU3-QWOXSVW-V4E75O4-BJ4DFC7-VWYVEMI-CSOAB24-6HYWCAK"; }; # As it was mainly made of wood (originally)
          "darko" = { id = "IJ6Z7AG-JESH6MF-DNUNQ7H-5C7ZESQ-DC6QK33-VCTNOQR-7S2KYGH-XTQBFAV"; };  # Just like the name, from Donnie Darko
          "mev" = { id = "F5SBWVX-KKGBIFU-IE3KFNO-BUFJQXT-Y7S3YME-OOKUHGG-BZRCSUX-PIR4HAS"; };    # Mobile Electric Visions
          "sirius" = { id = "7P47TAY-RTP6Z44-JWO2OK6-AU4XXPF-YZDWUBH-MZGNQLS-SHEP6YD-Y3FQLAQ"; }; # Brightest star in the galaxy (referring to Starlabs)
          "soono" = { id = "3ANAXVO-AISNYLS-PMAMNDO-3HP3PEH-JRTN7OA-PLYWPVJ-CZQT7XY-7LEWSAB"; };  # From Something of Nothing
        };
        folders = {
          "Sync" = {                                         # Name (and ID) of folder in Syncthing
            path = "/data/sync";                             # Which folder to add to Syncthing
            devices = [ "spruce" "darko" "sirius" "mev" "soono" ];   # Which devices to share the folder with
          };
          "Books" = {
            path = "/data/books";
            devices = [ "spruce" "darko" "sirius" "mev" "soono" ];
          };
          "Documents" = {
            path = "/data/documents";
            devices = [ "spruce" "darko" "sirius" "mev" "soono" ];
          };
          "Music" = {
            path = "/data/music";
            devices = [ "spruce" "darko" "sirius" "mev" "soono" ];
          };
          "Camera" = {
            path = "/data/pictures/camera";
            devices = [ "spruce" "darko" "sirius" "mev" "soono" ];
          };
          "Txt" = {
            path = "/data/txt";
            devices = [ "spruce" "darko" "sirius" "mev" "soono" ];
          };
          "Other" = {
            path = "/data/other";
            devices = [ "spruce" "darko" "sirius" ];
          };
          "Thunderbird" = {
            path = "/data/thunderbird_profile";
            devices = [ "spruce" "darko" "sirius" ];
          };
        };
      };
    };
  };
}