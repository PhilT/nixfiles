{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "start-apps" ''
      result=$(printf "Yes\nNo" | tofi -c /etc/config/tofi.ini --prompt-text "Sync from minoo? ")

      # Escape pressed - empty result means cancel
      if [ -z "$result" ]; then
        exit 0
      fi

      if [ "$result" = "Yes" ]; then
        app-sync-minoo chromium from
      fi

      /run/current-system/sw/bin/chromium &

      # Run g-dirty on startup and leave shell open
      swaymsg exec kitty -d $(g-dirty -s) --app-id=first-kitty --hold g-dirty -b

      move-window chromium workspace 8 &
      move-window first-kitty workspace 1 &
    '')
  ];
}
