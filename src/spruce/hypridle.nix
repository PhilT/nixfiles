let
  DIM = "300";    # 5 minutes
  LOCK = "600";   # 10 minutes
  OFF = "630";    # 10.5 minutes
  SLEEP = "1800"; # 30 minutes
in
{
  environment = {
    etc = {
      "xdg/hypr/hypridle.conf" = {
        mode = "444";
        text = ''
          general {
            # Avoid starting multiple hyprlock instances
            lock_cmd = pidof hyprlock || hyprlock

            # Lock before suspend
            before_sleep_cmd = loginctl lock-session

            # Avoid having to press a key twice to turn on the display
            after_sleep_cmd = hyprctl dispatch dpms on
          }

          listener {
            timeout = ${DIM}
            on-timeout = monlight down              # dim monitors
            on-resume = monlight up                 # brighten monitors
          }

          listener {
            timeout = ${LOCK}
            on-timeout = loginctl lock-session      # lock screen
          }

          listener {
            timeout = ${OFF}
            on-timeout = hyprctl dispatch dpms off  # screen off
            on-resume = hyprctl dispatch dpms on    # screen on
          }

          listener {
            timeout = ${SLEEP}
            on-timeout = systemctl suspend          # suspend pc
          }
        '';
      };
    };
  };
}