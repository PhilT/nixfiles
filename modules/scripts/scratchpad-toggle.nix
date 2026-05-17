{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "scratchpad-toggle" ''
      # scratchpad-toggle [--keep-focus] <mark>
      # If the marked window is currently visible, hide it.
      # Otherwise show it on the non-focused output (so it doesn't
      # cover what you're working on). With a single output, just shows.
      # --keep-focus leaves focus on the summoned window instead of
      # returning to the originally focused output.

      keep_focus=0
      if [ "$1" = "--keep-focus" ]; then
        keep_focus=1
        shift
      fi

      mark="$1"
      if [ -z "$mark" ]; then
        echo "usage: scratchpad-toggle [--keep-focus] <mark>" >&2
        exit 2
      fi

      tree=$(${sway}/bin/swaymsg -t get_tree)
      visible=$(echo "$tree" | ${jq}/bin/jq --arg m "$mark" '
        [.. | objects | select(.marks? and (.marks | index($m))) | select(.visible == true)] | length
      ')

      state_file="''${XDG_RUNTIME_DIR:-/tmp}/scratchpad-toggle-$mark"

      if [ "$visible" -gt 0 ]; then
        # `scratchpad show` on a visible window moves it to the focused
        # workspace if that differs; `move scratchpad` always stashes.
        ${sway}/bin/swaymsg "[con_mark=\"$mark\"] move scratchpad"
        # Return focus to the workspace that was focused before showing
        if [ -s "$state_file" ]; then
          prev=$(cat "$state_file")
          rm -f "$state_file"
          ${sway}/bin/swaymsg "workspace $prev"
        fi
        exit 0
      fi

      # Remember the currently focused workspace so we can return to it on hide
      ${sway}/bin/swaymsg -t get_workspaces \
        | ${jq}/bin/jq -r '.[] | select(.focused) | .name' > "$state_file"

      focused_output=$(${sway}/bin/swaymsg -t get_workspaces \
        | ${jq}/bin/jq -r '.[] | select(.focused) | .output')
      other_output=$(${sway}/bin/swaymsg -t get_outputs \
        | ${jq}/bin/jq -r --arg f "$focused_output" \
            'map(select(.active and .name != $f)) | .[0].name // empty')

      if [ -n "$other_output" ]; then
        ${sway}/bin/swaymsg "focus output $other_output"
        ${sway}/bin/swaymsg "[con_mark=\"$mark\"] scratchpad show"
        if [ "$keep_focus" -eq 0 ]; then
          ${sway}/bin/swaymsg "focus output $focused_output"
        fi
      else
        ${sway}/bin/swaymsg "[con_mark=\"$mark\"] scratchpad show"
      fi
    '')
  ];
}
