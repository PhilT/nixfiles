{ config, pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      lxde.lxmenu-data      # List apps to run in PCManFM
      pcmanfm
      ranger                # Terminal file manager
    ];

    # TODO: How would this be useful for ranger?
    etc."config/gtk-3.0/bookmarks" = {
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

  systemd.tmpfiles.rules = [
    "L+ ${config.xorg.xdgConfigHome}/gtk-3.0/bookmarks - - - - /etc/config/gtk-3.0/bookmarks"
  ];
}
