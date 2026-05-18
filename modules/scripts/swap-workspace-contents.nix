{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "swap-workspace-contents" ''
      # Swap windows between the focused workspace and the workspace
      # currently visible on the other output. Workspace numbers stay
      # put; only the windows move. Focus ends on the other workspace.

      ws_json=$(${sway}/bin/swaymsg -t get_workspaces)
      tree_json=$(${sway}/bin/swaymsg -t get_tree)

      a_num=$(echo "$ws_json" | ${jq}/bin/jq -r '.[] | select(.focused) | .num')
      a_output=$(echo "$ws_json" | ${jq}/bin/jq -r '.[] | select(.focused) | .output')

      b_num=$(echo "$ws_json" \
        | ${jq}/bin/jq -r --arg out "$a_output" \
            '.[] | select(.visible and .output != $out) | .num' \
        | head -n1)

      if [ -z "$b_num" ] || [ "$b_num" = "null" ]; then
        ${libnotify}/bin/notify-send "Swap contents" "No other visible workspace to swap with."
        exit 0
      fi

      ids_on() {
        echo "$tree_json" | ${jq}/bin/jq --argjson n "$1" -r '
          .. | objects
          | select(.type == "workspace" and .num == $n)
          | [.. | objects | select(.type == "con" or .type == "floating_con") | select(.pid != null) | .id]
          | .[]
        '
      }

      mapfile -t a_ids < <(ids_on "$a_num")
      mapfile -t b_ids < <(ids_on "$b_num")

      for id in "''${a_ids[@]}"; do
        ${sway}/bin/swaymsg "[con_id=$id] move container to workspace number $b_num" >/dev/null
      done
      for id in "''${b_ids[@]}"; do
        ${sway}/bin/swaymsg "[con_id=$id] move container to workspace number $a_num" >/dev/null
      done

      ${sway}/bin/swaymsg "workspace number $b_num" >/dev/null
    '')
  ];
}
