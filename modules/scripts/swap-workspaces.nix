{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "swap-workspaces" ''
      # Toggle: swap workspaces 1-5 <-> 6-10 between DP-2 and DP-3.
      #
      # `workspace N output X` only takes effect at config-load time
      # (sway(5)), so for empty workspaces to land on the right output
      # we have to write a config snippet and reload sway. The snippet
      # lives at ~/.config/sway/overrides/workspaces.conf, which is
      # included from the main sway config via a glob.

      overrides_dir="$HOME/.config/sway/overrides"
      overrides_file="$overrides_dir/workspaces.conf"
      mkdir -p "$overrides_dir"

      if [ -s "$overrides_file" ]; then
        rm -f "$overrides_file"
        mode="default"
      else
        {
          for n in 1 2 3 4 5;  do echo "workspace $n output DP-2"; done
          for n in 6 7 8 9 10; do echo "workspace $n output DP-3"; done
        } > "$overrides_file"
        mode="swapped"
      fi

      # The reload fires output events that sway-output-listener catches,
      # which invokes restore-workspaces. No need to call it explicitly.
      ${sway}/bin/swaymsg reload

      ${libnotify}/bin/notify-send "Workspaces $mode"
    '')
  ];
}
