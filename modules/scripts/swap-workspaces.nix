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
        # Currently swapped -> restore default
        rm -f "$overrides_file"
        left_nums="6 7 8 9 10"   # DP-2 (left)
        right_nums="1 2 3 4 5"   # DP-3 (right)
        mode="default"
      else
        # Currently default -> apply swap
        {
          for n in 1 2 3 4 5;  do echo "workspace $n output DP-2"; done
          for n in 6 7 8 9 10; do echo "workspace $n output DP-3"; done
        } > "$overrides_file"
        left_nums="1 2 3 4 5"
        right_nums="6 7 8 9 10"
        mode="swapped"
      fi

      ${sway}/bin/swaymsg reload

      # restore-workspaces consults the override file and applies the
      # correct layout (workspace moves + floating window repositioning).
      restore-workspaces

      ${libnotify}/bin/notify-send "Workspaces $mode"
    '')
  ];
}
