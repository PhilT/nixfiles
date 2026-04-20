{ config, lib, pkgs, ... }:
let
  ws = import ./workspaces.nix;
  resolveOutput = key: ws.outputs.${key};

  # Generate: workspace 1 output DP-3 eDP-1
  workspaceOutputLines = lib.concatStringsSep "\n" (lib.mapAttrsToList (num: outputKey:
    "workspace ${num} output ${resolveOutput outputKey} ${ws.outputs.fallback}"
  ) ws.assignments);

  # Generate: workspace 6 gaps left 982
  workspaceGapLines = lib.concatStringsSep "\n" (lib.filter (s: s != "") (lib.mapAttrsToList (num: outputKey:
    if outputKey == "primary"
    then "workspace ${num} gaps left ${toString ws.leftGap}"
    else ""
  ) ws.assignments));

  # Generate for_window rules for floating windows
  floatingWindowRules = lib.concatStringsSep "\n" (map (fw: ''
    for_window [app_id="${fw.appId}"] move to output ${resolveOutput "primary"}
    for_window [app_id="${fw.appId}"] floating enable, sticky enable, resize set ${toString fw.width} ${toString fw.height}, move position ${toString fw.x} ${toString fw.y}''
  ) ws.floatingWindows);

  # Generate exec move-window commands for floating windows
  floatingWindowExecs = lib.concatStringsSep "\n" (map (fw:
    "exec move-window ${fw.appId} absolute position ${toString fw.x} ${toString fw.y}"
  ) ws.floatingWindows);
in {
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
        output DP-2 scale 1
        output DP-2 pos 0 0

        # Seedling
        output DP-3 pos 3840 0

        ${workspaceOutputLines}

        xwayland enable

        # This only works in sway
        # See src/common.nix for console setting
        input * {
          xkb_layout "${config.keyboardLayout}"
          xkb_variant "${config.keyboardVariant}"
          xkb_options "${config.keyboardOptions}"
        }

        input type:touchpad {
          natural_scroll enabled
          tap enabled
        }

        input "9011:26214:ydotoold_virtual_device" xkb_layout us

        focus_follows_mouse yes

        output eDP-1 background /data/pictures/wallpaper/wallpaper-left.jpg fill
        output DP-2 background /data/pictures/wallpaper/wallpaper-left.jpg fill
        output DP-3 background /data/pictures/wallpaper/wallpaper-right.jpg fill

        exec swayidle -w \
          timeout 300 'light dim' resume 'light bright' \
          timeout 600 'light off' resume 'light on && sleep 3 && light bright' \
          after-resume 'light on'
        #timeout 300 'swaylock -f -c 363a4f'

        # Prevent screen timeout when windows are fullscreen (e.g., gaming)
        for_window [app_id=".*"] inhibit_idle fullscreen


        #timeout 900 'systemctl suspend'

        # Ensure folder icons are configured
        exec dconf write /org/gnome/desktop/interface/icon-theme "'cat-mocha-lavender'"
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
        assign [app_id="thunderbird"] workspace number 7
        assign [title="Claude"] workspace number 9

        # Set a gap on the left of all workspaces on the left so we add our keymap and Colemak Neovim cheatsheet.
        ${lib.optionalString (config.machine == "spruce") ''
          ${workspaceGapLines}
        ''}

        # Keymapp & Neovim Shortcuts: floating windows visible on all workspaces on left output, placed in the gap made above
        ${floatingWindowRules}

        # Run keymapp & Glow markdown viewer
        ${lib.optionalString (config.machine == "spruce") ''
          exec keymapp
          exec kitty --app-id=colemak --hold -d ${config.codeDir}/nixfiles glow -t -w 0 -s dotfiles/glow.json
        ''}

        # Open a terminal in the current directory
        bindsym $mod+c exec sh -c 'kitty_pid=$(swaymsg -t get_tree | jq ".. | select(.focused?) | .pid"); shell_pid=$(pstree -p $kitty_pid | grep -oE "(fish|bash|zsh|sh)\([0-9]+\)" | head -1 | grep -oP "\d+"); cwd=$(readlink /proc/$shell_pid/cwd 2>/dev/null || echo ~); kitty -d "$cwd"'
        bindsym $mod+Shift+c exec kitty
        bindsym $mod+Shift+Mod1+q exit
        bindsym ctrl+q exec quit-chromium
        bindsym $mod+w exec chromium
        bindsym $mod+f exec thunar
        bindsym $mod+t exec thunderbird
        bindsym $mod+a exec slack
        bindsym $mod+r exec renoise
        bindsym $mod+Shift+s exec slurp | grim -g - /data/screenshots/$(date +"%Y%m%d-%H%M%S").png
        bindsym $mod+p exec tofi-run -c /etc/config/tofi.ini | sh
        bindsym $mod+o exec keepmenu -c /etc/config/keepmenu.ini &

        # Left-click - move, right-click - resize
        floating_modifier $mod normal

        bindsym $mod+Shift+space fullscreen toggle
        bindsym $mod+space floating toggle
        bindsym $mod+Shift+f focus mode_toggle
        bindsym $mod+Shift+r reload

        # Move your focus
        bindsym $mod+h focus left
        bindsym $mod+j focus down
        bindsym $mod+k focus up
        bindsym $mod+l focus right
        # Colemak
        bindsym $mod+m focus left
        bindsym $mod+n focus down
        bindsym $mod+e focus up
        bindsym $mod+i focus right

        # Move focused window
        bindsym $mod+Shift+h move left
        bindsym $mod+Shift+j move down
        bindsym $mod+Shift+k move up
        bindsym $mod+Shift+l move right
        # Colemak
        bindsym $mod+Shift+m move left
        bindsym $mod+Shift+n move down
        bindsym $mod+Shift+e move up
        bindsym $mod+Shift+i move right

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

        # Move focused container to workspace and switch to it
        bindsym $mod+Ctrl+1 move container to workspace number 1; workspace number 1
        bindsym $mod+Ctrl+2 move container to workspace number 2; workspace number 2
        bindsym $mod+Ctrl+3 move container to workspace number 3; workspace number 3
        bindsym $mod+Ctrl+4 move container to workspace number 4; workspace number 4
        bindsym $mod+Ctrl+5 move container to workspace number 5; workspace number 5
        bindsym $mod+Ctrl+6 move container to workspace number 6; workspace number 6
        bindsym $mod+Ctrl+7 move container to workspace number 7; workspace number 7
        bindsym $mod+Ctrl+8 move container to workspace number 8; workspace number 8
        bindsym $mod+Ctrl+9 move container to workspace number 9; workspace number 9
        bindsym $mod+Ctrl+0 move container to workspace number 10; workspace number 10

        # Horizontal or Vertical split
        bindsym $mod+b splith
        bindsym $mod+v splitv

        # Switch the current container between different layout styles
        bindsym $mod+Ctrl+s layout stacking
        # bindsym $mod+t layout tabbed
        bindsym $mod+Ctrl+t layout toggle
        bindsym $mod+Ctrl+q layout toggle split

        bindsym $mod+Ctrl+r mode "resize"
        mode "resize" {
          bindsym n resize shrink width 10px
          bindsym e resize grow height 10px
          bindsym i resize shrink height 10px
          bindsym o resize grow width 10px

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
        bindsym $mod+Ctrl+l exec swaylock -f -c 363a4f

        # Styling

        # Cycle through border styles
        bindsym $mod+Ctrl+b border toggle

        gaps inner 2
        gaps outer 2
        default_border pixel 3

        # target                 title     bg    text   indicator  border
        client.focused           $lavender $base $text  $rosewater $lavender
        client.focused_inactive  $overlay0 $base $text  $rosewater $overlay0
        client.unfocused         $overlay0 $base $text  $rosewater $overlay0
        client.urgent            $peach    $base $peach $overlay0  $peach
        client.placeholder       $overlay0 $base $text  $overlay0  $overlay0
        client.background        $base

        # Cursors
        seat * xcursor_theme catppuccin-mocha-lavender-cursors 48

        # Needed for UWSM to start
        exec systemctl --user set-environment XDG_CURRENT_DESKTOP=sway
        exec uwsm finalize DISPLAY SWAYSOCK WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

        # Start Chromium and Thunderbird which sync their profiles with the server
        # before starting.
        exec ch move
        exec tb move

        # move-window is currently defined in src/chromium.nix
        ${floatingWindowExecs}

        # Restore workspaces when outputs reconnect (e.g. after suspend)
        ${lib.optionalString (config.machine == "spruce") ''
          exec sway-output-listener
        ''}

        # Run g-dirty on startup and leave shell open
        exec kitty -d $(g-dirty -s) --app-id=first-kitty --hold g-dirty -b
        exec move-window first-kitty workspace 1
      '';
    };
  };
}