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
      "config/gtk-3.0/bookmarks" = {
        mode = "444";
        text = ''
          file:///data/code code
          file:///data/documents documents
          file:///data/downloads downloads
          file:///data/music music
          file:///data/pictures pictures
          file:///data/software software
          file:///data/sync sync
          file:///data/txt txt
        '';
      };
    };
  };

  # https://www.freedesktop.org/software/systemd/man/tmpfiles.d.html
  # man tmpfiles.d
  systemd.tmpfiles.rules = [
    "d ${config.xorg.xdgConfigHome}/ranger - phil users -" # For some reason ranger needs write access to this dir
    "L+ ${config.xorg.xdgConfigHome}/gtk-3.0/bookmarks - - - - /etc/config/gtk-3.0/bookmarks"
    "L+ ${config.xorg.xdgConfigHome}/ranger/rc.conf - - - - /etc/config/ranger/rc.conf"
  ];
}
