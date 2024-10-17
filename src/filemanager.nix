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

  };

  # https://www.freedesktop.org/software/systemd/man/tmpfiles.d.html
  # man tmpfiles.d
  systemd.tmpfiles.rules = [
    "d ${config.xdgConfigHome} - ${config.username} users -"
    "d ${config.xdgConfigHome}/gtk-3.0 - ${config.username} users -"

    "L+ ${config.xdgConfigHome}/gtk-3.0/bookmarks - - - - /etc/config/gtk-3.0/bookmarks"
  ];
}