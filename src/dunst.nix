{ config, pkgs, ... }:
{
  environment.etc = {
    "config/dunstrc" = {
      mode = "444";
      text = ''
        [global]
        font = Monospace 10
        corner_radius = 4

        frame_color = "#8aadf4"
        separator_color = frame

        [urgency_low]
        background = "#24273a"
        foreground = "#cad3f5"

        [urgency_normal]
        background = "#24273a"
        foreground = "#cad3f5"

        [urgency_critical]
        background = "#24273a"
        foreground = "#cad3f5"
        frame_color = "#f5a97f"
      '';
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.xdgConfigHome}/dunst - phil users -"
    "L+ ${config.xdgConfigHome}/dunst/dunstrc - - - - /etc/config/dunstrc"
  ];
}
