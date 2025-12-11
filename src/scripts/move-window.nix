{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "move-window" ''
      app="$1"
      shift
      what=$@

      notify-send "Moving $app to $what"
      # Move apps as quickly as possible but keep trying for slower machines.
      # Positioning requires multiple attempts to get it to the right point.
      for i in {1..5}; do
        sleep 1
        swaymsg "[app_id=$app] move $what"
      done
    '')
  ];
}