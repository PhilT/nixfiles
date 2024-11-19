{ config, pkgs, ... }: {
  programs.thunar.enable = true;
  programs.thunar.plugins = with pkgs.xfce; [
    thunar-volman
    thunar-archive-plugin
    thunar-media-tags-plugin
  ];

  environment = {
    systemPackages = with pkgs; [
      file-roller           # GUI archiver
      lxde.lxmenu-data      # List apps to run in PCManFM
    ];

    etc = {
      # TODO: How would this be useful for ranger?
      # TODO: Need to set the downloads directory in Firefox
      "config/gtk-3.0/bookmarks" = {
        mode = "444";
        text = ''
          file:///data/code/matter matter
          file:///data data
          file:///data/code code
          file:///data/spikes spikes
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

      "config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml" = {
        mode = "444";
        text = ''
          <?xml version="1.0" encoding="UTF-8"?>

          <channel name="thunar" version="1.0">
            <property name="last-view" type="string" value="ThunarCompactView"/>
            <property name="last-details-view-visible-columns" type="string" value="THUNAR_COLUMN_DATE_MODIFIED,THUNAR_COLUMN_NAME,THUNAR_COLUMN_SIZE,THUNAR_COLUMN_TYPE"/>
            <property name="last-show-hidden" type="bool" value="true"/>
          </channel>
        '';
      };
    };
  };

  # https://www.freedesktop.org/software/systemd/man/tmpfiles.d.html
  # man tmpfiles.d
  systemd.tmpfiles.rules = [
    "d ${config.xdgConfigHome} - ${config.username} users -"
    "d ${config.xdgConfigHome}/gtk-3.0 - ${config.username} users -"
    "d ${config.xdgConfigHome}/xfce4/xfconf/xfce-perchannel-xml - ${config.username} users -"

    "L+ ${config.xdgConfigHome}/gtk-3.0/bookmarks - - - - /etc/config/gtk-3.0/bookmarks"
    "L+ ${config.xdgConfigHome}/xfce4/xfconf/xfce-perchannel-xml/thunar.xml - - - - /etc/config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml"
  ];
}