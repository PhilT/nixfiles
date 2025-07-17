{ config, lib, pkgs, ... }:
let
  colors = import ../macchiato.nix lib;
in with colors;
{
  programs.sway.extraPackages = with pkgs; [
    waybar
  ];

  environment.etc = {
    "xdg/waybar/config.jsonc" = {
      mode = "444";
      text = (builtins.toJSON {
        layer = "top";
        spacing = "8";
        height = "30";
        modules-left = ["sway/workspaces"];
        modules-center = ["sway/window"];
        modules-right = config.waybarModules;
        backlight = {
          format = "{}{icon}";
          format-icons = ["󱩏"];
        };
        "sway/workspaces" = {
          window-rewrite = {};
          format = "{icon}";
          on-click = "activate";
          format-icons = {
            "10" = "0";
          };
          sort-by-number = true;
          persistent-workspaces = {
            "1" = ["DP-1" "eDP-1"];
            "2" = ["DP-1" "eDP-1"];
            "3" = ["DP-1" "eDP-1"];
            "4" = ["DP-1" "eDP-1"];
            "5" = ["DP-1" "eDP-1"];
            "6" = ["HDMI-A-1" "eDP-1"];
            "7" = ["HDMI-A-1" "eDP-1"];
            "8" = ["HDMI-A-1" "eDP-1"];
            "9" = ["HDMI-A-1" "eDP-1"];
            "10" = ["HDMI-A-1" "eDP-1"];
          };
        };
        "sway/window" = {
          max-length = 50;
        };
        battery = {
          format = "{capacity}% {icon}";
          format-icons = ["" "" "" "" ""];
        };
        clock = {
          format-alt = "{:%a, %d. %b  %H:%M}";
        };
        cpu = {
          format = "{usage}% 󰻠";
          tooltip = false;
        };
        memory = {
          format = "{avail} 󰍛";
        };
        disk = {
          format = "{specific_free:0.2f} GB";
          unit = "GB";
          path = "/";
        };
        temperature = {
          thermal-zone = 1;
          critical-threshold = 80;
          format = "{temperatureC}°C {icon}";
          format-icons = ["" "" ""];
        };
        network = {
          format-wifi = "{icon}";
          format-ethernet = "{ifname}";
          format-disconnected = "";
          max-length = 50;
          on-click = "kitty nmtui";
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
        bluetooth = {
          on-click = "overskride";
          format = " {status}";
          format-connected = " {device_alias}";
          format-connected-battery = " {device_alias} {device_battery_percentage}%";
          tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
        };
        tray = {
          icon-size = 24;
        };
      });
    };

    "xdg/waybar/style.css" = {
      mode = "444";
      text = ''

        * {
          all: unset;
          border: none;
          border-radius: 4px;
          font-family: JetBrains Mono;
          font-size: 24px;
          min-height: 0;
        }

        window#waybar {
          color: ${rgb text};
          background-color: ${rgba base "0.9"};
          transition-property: background-color;
          transition-duration: .5s;
          border-radius: 0;
        }

        window#waybar.hidden {
          opacity: 0.2;
        }

        tooltip {
          background: ${rgba base 0.9};
          border: 1px solid ${rgba overlay0 "0.8"};
        }

        tooltip label {
          color: ${rgb text};
        }

        #workspaces button {
          background-color: ${rgba lavender "0.3"};
          padding: 2px 12px 0;
          margin: 2px;
          color: ${rgb text};
          border-bottom-left-radius: 0;
          border-bottom-right-radius: 0;
        }

        #workspaces button.empty {
          background-color: transparent;
        }

        #workspaces button:hover {
          background: ${rgba crust 0.2};
        }

        #workspaces button.visible {
          border-bottom: 3px solid ${rgb lavender};
        }

        #workspaces button.active {
          background-color: ${rgb lavender};
          color: ${rgb base};
        }

        #workspaces button.urgent {
          background-color: ${rgb red};
        }

        #mode {
          background-color: ${rgb overlay0};
          border-bottom: 3px solid ${rgb text};
        }

        #clock,
        #battery,
        #cpu,
        #memory,
        #disk,
        #temperature,
        #backlight,
        #network,
        #pulseaudio,
        #custom-weather,
        #tray,
        #mode,
        #idle_inhibitor,
        #custom-notification,
        #sway-scratchpad,
        #mpd {
          background-color: ${rgb surface1};
          padding: 0 5px;
          margin: 3px 2px;
          color: ${rgb text};
        }

        #network,
        #cpu,
        #backlight,
        #battery {
          padding-right: 8px;
        }

        #window,
        #workspaces {
          margin: 0 2px;
        }

        /* If workspaces is the leftmost module, omit left margin */
        .modules-left > widget:first-child > #workspaces {
          margin-left: 0;
        }

        /* If workspaces is the rightmost module, omit right margin */
        .modules-right > widget:last-child > #workspaces {
          margin-right: 0;
        }

        #battery.charging, #battery.plugged {
          color: @battery-plugged;
          background-color: @battery;
        }

        @keyframes blink {
          to {
            background-color: #ffffff;
            color: #000000;
          }
        }

        #battery.critical:not(.charging) {
          background-color: ${rgb red};
          color: ${rgb rosewater};
          animation-name: blink;
          animation-duration: 0.5s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
        }

        label:focus {
          background-color: #000000;
        }

        #network.disconnected {
          background-color: @network-disconnected;
          color: @text;
        }

        #pulseaudio.muted {
          background-color: ${rgb surface1};
        }

        #custom-media.custom-spotify {
          background-color: ${rgb green};
        }

        #custom-media.custom-vlc {
          background-color: ${rgb peach};
        }

        #temperature.critical {
          background-color: ${rgb red};
        }

        #tray > .passive {
          -gtk-icon-effect: dim;
        }

        #tray > .needs-attention {
          -gtk-icon-effect: highlight;
          background-color: ${rgb red};
        }

        #idle_inhibitor {
          background-color: ${rgb surface1};
          color: ${rgb text};
        }

        #idle_inhibitor.activated {
          background-color: ${rgb text};
          color: ${rgb surface1};
        }

        #mpd {
          background-color: ${rgb teal};
          color: ${rgb base};
        }

        #mpd.disconnected {
          background-color: ${rgb red};
        }

        #mpd.stopped {
          background-color: ${rgb overlay2};
        }

        #mpd.paused {
          background-color: ${rgba teal "0.5"};
        }

        #custom-weather {
          background-color: ${rgb sky};
          color: ${rgb base};
          margin-right: 5px;
        }

        #disk {
          background-color: @disk;
          color: @text;
        }

        #sway-scratchpad {
          background-color: ${rgb green};
          color: ${rgb base};
        }
      '';
    };
  };
}