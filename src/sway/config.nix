{ config, lib, pkgs, ... }: {
  environment.etc = {
    "sway/config" = {
      mode = "444";
      text = ''
        # Needed for screen sharing but included in config.d/
        # exec dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
        include /etc/sway/config.d/*

        # Some defaults
        output * scale 1
        output * pos 0 0

        # Spruce
        output DP-1 scale 1
        output HDMI-A-1 scale 1
        output HDMI-A-1 pos 0 0
        output DP-1 pos 3840 0

        workspace 1 output DP-1 eDP-1
        workspace 2 output DP-1 eDP-1
        workspace 3 output DP-1 eDP-1
        workspace 4 output DP-1 eDP-1
        workspace 5 output DP-1 eDP-1
        workspace 6 output HDMI-A-1 eDP-1
        workspace 7 output HDMI-A-1 eDP-1
        workspace 8 output HDMI-A-1 eDP-1
        workspace 9 output HDMI-A-1 eDP-1
        workspace 0 output HDMI-A-1 eDP-1

        xwayland enable

        # This only works in sway
        # See src/common.nix for console setting
        input type:keyboard {
          xkb_layout ${config.keyboardLayout}
          xkb_options ctrl:nocaps
        }

        input type:touchpad {
          natural_scroll enabled
          tap enabled
        }

        input "9011:26214:ydotoold_virtual_device" xkb_layout us

        focus_follows_mouse yes

        output eDP-1 background /data/pictures/wallpaper/wallpaper-left.jpg fill
        output DP-1 background /data/pictures/wallpaper/wallpaper-right.jpg fill
        output HDMI-A-1 background /data/pictures/wallpaper/wallpaper-left.jpg fill

        exec swayidle -w \
          timeout 300 'light dim' resume 'light bright' \
          timeout 600 'light off' resume 'light on && sleep 3 && light bright' \
          after-resume 'light on'


        #timeout 900 'systemctl suspend'
        #before-sleep 'swaylock -f -c 363a4f'

        # Ensure folder icons are configured
        exec dconf write /org/gnome/desktop/interface/icon-theme "'cat-macchiato-lavender'"
        exec dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
        exec dconf write /org/gnome/desktop/interface/text-scaling-factor "2.0"
        exec dconf write /org/gnome/desktop/interface/cursor-size "48"
        exec dconf write /org/gtk/settings/file-chooser/show-hidden "True"

        exec darkman set dark # Force dark mode in QT apps such as KeePassXC - Running KeePassXC a second time doesn't apply darkmode

        exec waybar
        exec mako -c /etc/config/mako

        # Windows/Super key as main modifier
        set $mod Mod4

        # Set some apps to load into certain workspace
        assign [app_id="Slack"] workspace number 6

        # PROGRAMS
        bindsym $mod+y exec cd /data/code/nixfiles && bin/vm sapling deadbeef
        bindsym $mod+u exec cd /data/code/nixfiles && bin/vm seedling deadbeee
        bindsym $mod+c exec kitty
        bindsym $mod+Shift+q kill
        bindsym $mod+Shift+Mod1+q exit
        bindsym $mod+w exec firefox-esr
        bindsym $mod+f exec thunar
        bindsym $mod+e exec thunderbird
        bindsym $mod+a exec slack
        bindsym $mod+n exec renoise
        bindsym $mod+Shift+s exec slurp | grim -g - /data/screenshots/$(date +"%Y%m%d-%H%M%S").png
        bindsym $mod+p exec tofi-run -c /etc/config/tofi.ini | sh
        bindsym $mod+o exec keepmenu -c /etc/config/keepmenu.ini &

        # Left-click - move, right-click - resize
        floating_modifier $mod normal

        bindsym $mod+Shift+space fullscreen toggle
        bindsym $mod+space floating toggle
        bindsym $mod+Shift+r reload

        # Move your focus
        bindsym $mod+h focus left
        bindsym $mod+j focus down
        bindsym $mod+k focus up
        bindsym $mod+l focus right

        # Move focused window
        bindsym $mod+Shift+h move left
        bindsym $mod+Shift+j move down
        bindsym $mod+Shift+k move up
        bindsym $mod+Shift+l move right

        # Previous workspace
        bindsym $mod+tab workspace back_and_forth
        bindsym $mod+Shift+tab workspace prev

        # Switch to workspace
        bindsym $mod+1 workspace number 1
        bindsym $mod+2 workspace number 2
        bindsym $mod+3 workspace number 3
        bindsym $mod+4 workspace number 4
        bindsym $mod+5 workspace number 5
        bindsym $mod+6 workspace number 6
        bindsym $mod+7 workspace number 7
        bindsym $mod+8 workspace number 8
        bindsym $mod+9 workspace number 9
        bindsym $mod+0 workspace number 10

        # Move focused container to workspace
        bindsym $mod+Shift+1 move container to workspace number 1
        bindsym $mod+Shift+2 move container to workspace number 2
        bindsym $mod+Shift+3 move container to workspace number 3
        bindsym $mod+Shift+4 move container to workspace number 4
        bindsym $mod+Shift+5 move container to workspace number 5
        bindsym $mod+Shift+6 move container to workspace number 6
        bindsym $mod+Shift+7 move container to workspace number 7
        bindsym $mod+Shift+8 move container to workspace number 8
        bindsym $mod+Shift+9 move container to workspace number 9
        bindsym $mod+Shift+0 move container to workspace number 10

        # Horizontal or Vertical split
        bindsym $mod+b splith
        bindsym $mod+v splitv

        # Switch the current container between different layout styles
        bindsym $mod+s layout stacking
        bindsym $mod+t layout tabbed
        bindsym $mod+q layout toggle split

        bindsym $mod+r mode "resize"
        mode "resize" {
          bindsym h resize shrink width 10px
          bindsym j resize grow height 10px
          bindsym k resize shrink height 10px
          bindsym l resize grow width 10px

          # Return to default mode
          bindsym Return mode "default"
          bindsym Escape mode "default"
        }

        #######################################
        # Sway has a "scratchpad", which is a bag of holding for windows.
        # You can send windows there and get them back later.

        # Move the currently focused window to the scratchpad
        bindsym $mod+Shift+minus move scratchpad

        # Show the next scratchpad window or hide the focused scratchpad window.
        # If there are multiple scratchpad windows, this command cycles through them.
        bindsym $mod+minus scratchpad show
        #######################################

        # Volume and Media Control
        bindsym --locked XF86AudioRaiseVolume exec pamixer -i 5
        bindsym --locked XF86AudioLowerVolume exec pamixer -d 5
        bindsym --locked XF86AudioMicMute exec pamixer --default-source -m
        bindsym --locked XF86AudioMute exec pamixer -t
        bindsym --locked XF86AudioPlay exec playerctl play-pause
        bindsym --locked XF86AudioPause exec playerctl play-pause
        bindsym --locked XF86AudioNext exec playerctl next
        bindsym --locked XF86AudioPrev exec playerctl previous

        # Screen brightness
        bindsym XF86MonBrightnessUp exec light up
        bindsym XF86MonBrightnessDown exec light down

        # MONITORS
        bindsym $mod+comma focus output left
        bindsym $mod+period focus output right

        # OS
        bindsym --release $mod+Shift+backspace exec systemctl suspend
        bindsym $mod+Ctrl+backspace exec shutdown now
        bindsym $mod+Ctrl+Shift+backspace exec reboot

        # Styling

        # Cycle through border styles
        bindsym $mod+Ctrl+b border toggle

        gaps inner 2
        gaps outer 2
        default_border pixel 2

        # target                 title     bg    text   indicator  border
        client.focused           $lavender $base $text  $rosewater $lavender
        client.focused_inactive  $overlay0 $base $text  $rosewater $overlay0
        client.unfocused         $overlay0 $base $text  $rosewater $overlay0
        client.urgent            $peach    $base $peach $overlay0  $peach
        client.placeholder       $overlay0 $base $text  $overlay0  $overlay0
        client.background        $base

        # Cursors
        seat * xcursor_theme catppuccin-macchiato-lavender-cursors 48

        # Needed for UWSM to start
        exec systemctl --user set-environment XDG_CURRENT_DESKTOP=sway
        exec uwsm finalize DISPLAY SWAYSOCK WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
      '';
    };
  };
}
