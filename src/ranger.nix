{ config, pkgs, ... }: {
  services = {
    # Automount USB drives
    gvfs.enable = true;
    udisks2.enable = true;
    devmon.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      shared-mime-info      # Recognise different file types
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
          file:///data/screenshots screenshots
          file:///data/software software
          file:///data/sync sync
          file:///data/notes notes
        '';
      };
    };
  };

  # https://www.freedesktop.org/software/systemd/man/tmpfiles.d.html
  # man tmpfiles.d
  systemd.tmpfiles.rules = [
    "d ${config.xdgConfigHome} - ${config.username} users -"
    "d ${config.xdgConfigHome}/ranger - ${config.username} users -" # For some reason ranger needs write access to this dir

    "L+ ${config.xdgConfigHome}/ranger/rc.conf - - - - /etc/config/ranger/rc.conf"
  ];
}