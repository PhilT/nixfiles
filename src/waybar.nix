{
  environment.etc = {
    "xdg/waybar/config.jsonc" = {
      mode = "444";
      text = (builtins.toJSON {
        layer = "top";
        modules-left = ["hyprland/workspaces"];
        modules-center = ["hyprland/window"];
        modules-right = [
          "pulseaudio"
          "network"
          "cpu"
          "memory"
          "temperature"
          "backlight"
          "battery"
          "clock"
          "tray"
        ];
        backlight = {
          format = "{}{icon}";
          format-icons = ["󱩏"];
        };
        "hyprland/workspaces" = {
          format = "{icon}";
          on-click = "activate";
          format-icons = {
            "10" = "0";
          };
          sort-by-number = true;
          persistent-workspaces = {
            DP-3 = [ 1 2 3 4 5 ];
            DP-2 = [ 6 7 8 9 10 ];
          };
        };
        "hyprland/window" = {
          max-length = 50;
        };
        battery = {
          format = "{capacity}% {icon}";
          format-icons = ["" "" "" "" ""];
        };
        clock = {
          format-alt = "{:%a, %d. %b  %H:%M}";
        };
        "cpu" = {
          format = "{usage}% ";
          tooltip = false;
        };
        memory = {
          format = "{}% ";
        };
        temperature = {
          critical-threshold = 80;
          format = "{temperatureC}°C {icon}";
          format-icons = ["" "" ""];
        };
        network = {
          format-wifi = "{icon}";
          format-ethernet = "{ifname}";
          format-disconnected = "";
          max-length = 50;
          on-click = "alacritty -e 'nmtui'";
          format-icons = ["󰤯" "󰤟" "󰤢" "󰤥" "󰤨"];
        };
        pulseaudio = {
          format = "{volume}% {icon} {format_source}";
          format-bluetooth = "{volume}% {icon} {format_source}";
          format-bluetooth-muted = " {icon} {format_source}";
          format-muted = " {format_source}";
          format-source = "{volume}% ";
          format-source-muted = "";
          format-icons = {
              headphone = "";
              hands-free = "";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = ["  " "  " "  "];
          };
          on-click = "pavucontrol";
        };
      });
    };
  };
}