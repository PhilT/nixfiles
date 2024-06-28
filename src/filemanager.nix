{ config, pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      lxde.lxmenu-data      # List apps to run in PCManFM
      pcmanfm
      ranger                # Terminal file manager
    ];

    etc = {
      "config/ranger/rc.conf" = {
        mode = "444";
        text = ''
          set preview_images_method kitty
        '';
      };

      # TODO: How would this be useful for ranger?
      # TODO: Need to set the downloads directory in Firefox
      "config/gtk-3.0/bookmarks" = {
        mode = "444";
        text = ''
          file:///data/code/matter matter
          file:///data data
          file:///data/code code
          file:///data/documents documents
          file:///data/downloads downloads
          file:///data/music music
          file:///data/pictures pictures
          file:///data/software software
          file:///data/sync sync
          file:///data/notes notes
          file:///games/steam/steamapps/common/rFactor%202 rFactor 2
        '';
      };
    };
  };

  # https://www.freedesktop.org/software/systemd/man/tmpfiles.d.html
  # man tmpfiles.d
  systemd.tmpfiles.rules = [
    "d ${config.xdgConfigHome} - phil users -"
    "d ${config.xdgConfigHome}/ranger - phil users -" # For some reason ranger needs write access to this dir
    "L+ ${config.xdgConfigHome}/gtk-3.0/bookmarks - - - - /etc/config/gtk-3.0/bookmarks"
    "L+ ${config.xdgConfigHome}/ranger/rc.conf - - - - /etc/config/ranger/rc.conf"
  ];
}