{ config, lib, pkgs, ... }:
let
  colors = import ./macchiato.nix lib;
  macchiato-gtk = pkgs.catppuccin-gtk.override ({
    accents = [ "lavender" ];
    variant = "macchiato";
  });
in with colors; {
  # [ ] Fix cursor size in Waybar & Firefox
  # [ ] Better way to setup bluetooth devices
  # [ ] Firefox bookmarks, settings, etc
  # [ ] Thunderbird config
  # [ ] Impermanence?
  # [x] Add hgrep (history)
  # [x] Cursors
  # [x] Themes
  # [x] Programs don't run from Tofi needed `| sh` at the end of the command
  # [x] keepmenu not working
  # [x] Win ENTER not working
  # [x] Shortcuts for `systemctl suspend`, `reboot`, `shutdown now` (configure power button)
  # [x] Replace SDDM with greetd (instead of Make SDDM look nicer)
  # [x] Move .config/hypr/hyprland.conf to Nix
  # [x] Move .config/waybar/config.jsonc to Nix
  # [x] Keyboard mappings?
  # [x] Workspace indicators
  # [x] Media keys
  # [x] Window borders/spacing
  # [x] Keyboard layout
  # [x] Fix touchpad scroll direction
  # [x] Remap CAPS
  # [x] Menu (dmenu?)

  imports = [
    <catppuccin/modules/nixos>
    ./waybar.nix
    ./dunst.nix
    ./tofi.nix
  ];

  programs.hyprland.enable = true;
  programs.waybar.enable = true;
  programs.hyprlock.enable = true; # Also installs hypridle

  catppuccin.enable = true;
  catppuccin.flavor = "macchiato";

  services.pipewire.enable = true; # Screen sharing
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.hyprland}/bin/Hyprland";
        user = "phil";
      };
    };
  };

  environment = {
    etc = {
      "xdg/hypr/hyprland.conf" = {
        mode = "444";
        text = ''
          source = ~/.config/hypr/machine.conf
          source = ~/.config/hypr/macchiato.conf

          monitor=,preferred,auto,1 # Default fallback - See hyprland-<machine>.conf

          # Fixes blurry UI in X apps such as Gimp
          xwayland {
          force_zero_scaling = true
          }
          # env = GDK_SCALE,2 # See if any programs need this

          exec-once = which iio-hyprland && iio-hyprland # Sirius
          exec-once = waybar
          exec-once = hyprpaper
          exec-once = hypridle
          exec-once = dunst
          exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP # Needed for screen sharing
          exec-once = hyprctl dispatch focusmonitor DP-3  # Focus on left monitor at startup
          exec-once = hcompact

          env = ELECTRON_OZONE_PLATFORM_HINT,auto # FIXME: Possibly not needed for non-nvidia
          env = XCURSOR_SIZE,32
          env = HYPRCURSOR_THEME,catppuccin-macchiato-lavender-cursors
          env = HYPRCURSOR_SIZE,32

          general {
            gaps_in = 2
            gaps_out = 2
            border_size = 2
            col.active_border =  ${hex flamingo} 45deg
            col.inactive_border = $overlay0
            resize_on_border = true
            allow_tearing = false
            layout = master
          }

          decoration {
            rounding = 3

            # Change transparency of focused and unfocused windows
            active_opacity = 1.0
            inactive_opacity = 1.0

            drop_shadow = true # true
            shadow_range = 4
            shadow_render_power = 3
            col.shadow = rgba(1a1a1aee)

            # https://wiki.hyprland.org/Configuring/Variables/#blur
            blur {
              enabled = true # true
              size = 3
              passes = 1

              vibrancy = 0.1696
            }
          }

          # https://wiki.hyprland.org/Configuring/Variables/#animations
          animations {
            enabled = true # true

            # Default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

            bezier = myBezier, 0.05, 0.9, 0.1, 1.05

            animation = windows, 1, 7, myBezier
            animation = windowsOut, 1, 7, default, popin 80%
            animation = border, 1, 5, default
            animation = borderangle, 1, 8, default
            animation = fade, 1, 7, default
            animation = workspaces, 1, 6, default
          }

          # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
          dwindle {
            pseudotile = true # Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
            preserve_split = true # You probably want this
          }

          # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
          master {
            new_status = master
          }

          # https://wiki.hyprland.org/Configuring/Variables/#misc
          misc {
            force_default_wallpaper = -1 # Set to 0 or 1 to disable the anime mascot wallpapers
            disable_hyprland_logo = false # If true disables the random hyprland logo / anime girl background. :(
            disable_splash_rendering = true # Disable splash text
          }


          #############
          ### INPUT ###
          #############

          # https://wiki.hyprland.org/Configuring/Variables/#input
          input {
            kb_layout = gb
            kb_variant =
            kb_model =
            kb_options = ctrl:nocaps
            kb_rules =

            follow_mouse = 1

            sensitivity = 0 # -1.0 - 1.0, 0 means no modification.

            touchpad {
              natural_scroll = true
            }
          }

          # https://wiki.hyprland.org/Configuring/Variables/#gestures
          gestures {
            workspace_swipe = false
          }

          # Example per-device config
          # See https://wiki.hyprland.org/Configuring/Keywords/#per-device-input-configs for more
          device {
            name = epic-mouse-v1
            sensitivity = -0.5
          }

          device {
            name = ydotoold-virtual-device
            kb_layout = us
            kb_variant =
            kb_options =
          }

          ###################
          ### KEYBINDINGS ###
          ###################

          # See https://wiki.hyprland.org/Configuring/Keywords/
          $mainMod = SUPER # Sets "Windows" key as main modifier

          # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more

          # PROGRAMS
          bind = $mainMod, C, exec, kitty
          bind = $mainMod, Q, killactive,
          bind = $mainMod SHIFT, Q, exit,
          bind = $mainMod, W, exec, [workspace 7] firefox-esr
          bind = $mainMod, F, exec, pcmanfm
          bind = $mainMod, E, exec, thunderbird
          bind = $mainMod, A, exec, [workspace 6] slack
          bind = $mainMod SHIFT, S, exec, hyprshot --freeze -m region -o /data/screenshots
          bind = $mainMod SHIFT, F, togglefloating,
          bind = $mainMod, P, exec, tofi-run -c /etc/config/tofi.ini | sh
          bind = $mainMod, up, pseudo, # dwindle
          bind = $mainMod, down, togglesplit, # dwindle
          bind = $mainMod, backslash, exec, keepmenu -c /etc/config/keepmenu.ini &

          # Cycle next/previous window
          bind = $mainMod, J, cyclenext, next
          bind = $mainMod, K, cyclenext, prev

          bind = $mainMod, return, layoutmsg, swapwithmaster
          bind = $mainMod, R, layoutmsg, orientationright

          bind = $mainMod, H, splitratio, -0.05
          bind = $mainMod, L, splitratio, +0.05

          # Switch workspaces with mainMod + [0-9]
          bind = $mainMod, 1, workspace, 1
          bind = $mainMod, 2, workspace, 2
          bind = $mainMod, 3, workspace, 3
          bind = $mainMod, 4, workspace, 4
          bind = $mainMod, 5, workspace, 5
          bind = $mainMod, 6, workspace, 6
          bind = $mainMod, 7, workspace, 7
          bind = $mainMod, 8, workspace, 8
          bind = $mainMod, 9, workspace, 9
          bind = $mainMod, 0, workspace, 10

          # Move active window to a workspace with mainMod + SHIFT + [0-9]
          bind = $mainMod SHIFT, 1, movetoworkspacesilent, 1
          bind = $mainMod SHIFT, 2, movetoworkspacesilent, 2
          bind = $mainMod SHIFT, 3, movetoworkspacesilent, 3
          bind = $mainMod SHIFT, 4, movetoworkspacesilent, 4
          bind = $mainMod SHIFT, 5, movetoworkspacesilent, 5
          bind = $mainMod SHIFT, 6, movetoworkspacesilent, 6
          bind = $mainMod SHIFT, 7, movetoworkspacesilent, 7
          bind = $mainMod SHIFT, 8, movetoworkspacesilent, 8
          bind = $mainMod SHIFT, 9, movetoworkspacesilent, 9
          bind = $mainMod SHIFT, 0, movetoworkspacesilent, 10

          bind = $mainMod CTRL, 1, movetoworkspace, 1
          bind = $mainMod CTRL, 2, movetoworkspace, 2
          bind = $mainMod CTRL, 3, movetoworkspace, 3
          bind = $mainMod CTRL, 4, movetoworkspace, 4
          bind = $mainMod CTRL, 5, movetoworkspace, 5
          bind = $mainMod CTRL, 6, movetoworkspace, 6
          bind = $mainMod CTRL, 7, movetoworkspace, 7
          bind = $mainMod CTRL, 8, movetoworkspace, 8
          bind = $mainMod CTRL, 9, movetoworkspace, 9
          bind = $mainMod CTRL, 0, movetoworkspace, 10

          # Example special workspace (scratchpad)
          bind = $mainMod, space, togglespecialworkspace, magic
          bind = $mainMod SHIFT, space, movetoworkspace, special:magic

          # Scroll through existing workspaces
          bind = $mainMod, tab, workspace, previous

          # Move/resize windows with mainMod + LMB/RMB and dragging
          bindm = $mainMod, mouse:272, movewindow
          bindm = $mainMod, mouse:273, resizewindow

          # Volume and Media Control
          bind = , XF86AudioRaiseVolume, exec, pamixer -i 5
          bind = , XF86AudioLowerVolume, exec, pamixer -d 5
          bind = , XF86AudioMicMute, exec, pamixer --default-source -m
          bind = , XF86AudioMute, exec, pamixer -t
          bind = , XF86AudioPlay, exec, playerctl play-pause
          bind = , XF86AudioPause, exec, playerctl play-pause
          bind = , XF86AudioNext, exec, playerctl next
          bind = , XF86AudioPrev, exec, playerctl previous

          # Screen brightness
          bind = , XF86MonBrightnessUp, exec, adjustlight up
          bind = , XF86MonBrightnessDown, exec, adjustlight down

          # MONITORS
          bind = $mainMod, comma, focusmonitor, -1
          bind = $mainMod, period, focusmonitor, +1

          # Move window to a monitor
          bind = $mainMod SHIFT, comma, movewindow, mon: -1
          bind = $mainMod SHIFT, period, movewindow, mon: +1

          # OS
          bind = $mainMod SHIFT, backspace, exec, systemctl suspend
          bind = $mainMod CTRL, backspace, exec, shutdown now
          bind = $mainMod CTRL SHIFT, backspace, exec, reboot

          windowrulev2 = suppressevent maximize, class:.* # You'll probably like this.
          windowrulev2 = move 0 0, class:feh
        '';
      };

      "xdg/hypr/hyprlock.conf".source = ../dotfiles/hyprlock.conf;
      "xdg/hypr/macchiato.conf".source = ../dotfiles/macchiato.conf;
    };

    systemPackages = with pkgs; [
      brightnessctl # TODO: Probably only needed for laptops
      macchiato-gtk
      catppuccin-cursors.macchiatoLavender
      dunst
      hyprpaper
      libnotify     # Used by hypridle
      hyprlandPlugins.hyprgrass
#    networkmanagerapplet
    ];


    sessionVariables = {
      GTK_THEME = "catppuccin-macchiato-lavender-standard";
      XCURSOR_THEME = "catppuccin-macchiato-lavender-cursors";

      NIXOS_OZONE_WL = "1"; # hint electron apps to use wayland:
      SDL_VIDEODRIVER = "wayland";
      _JAVA_AWT_WMNONREPARENTING = "1";
      QT_QPA_PLATFORM = "wayland";
      XDG_SESSION_TYPE = "wayland";
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
    };

  };

  systemd.tmpfiles.rules = [
    "d ${config.xdgConfigHome} - phil users -"
    "L+ ${config.xdgConfigHome}/hypr - - - - /etc/xdg/hypr"

    # Fix for cursors in Waybar/Firefox
    "L+ ${config.xdgDataHome}/icons/default - - - - ${pkgs.catppuccin-cursors.macchiatoLavender}/share/icons/catppuccin-macchiato-lavender-cursors"
  ];
}