{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "sway-workspace-nudge" ''
      # After 5 minutes focused on a workspace that lives on the non-main
      # output, prompt to swap workspaces between outputs.
      #
      # "Main" output is whichever one currently holds workspace 1.

      timeout=300
      timer_pid=""

      kill_timer() {
        if [ -n "$timer_pid" ]; then
          pkill -P "$timer_pid" 2>/dev/null
          kill "$timer_pid" 2>/dev/null
          timer_pid=""
        fi
      }

      prompt() {
        action=$(${libnotify}/bin/notify-send \
          --app-name=sway \
          --action="swap=Swap contents" \
          --wait \
          "Swap workspace contents?" \
          "You've been on this workspace for 5 minutes. Swap its windows with the main screen? (Mod+x)")
        if [ "$action" = "swap" ]; then
          swap-workspace-contents
        fi
      }

      maybe_start_timer() {
        local ws_json focused_num focused_output main_output
        ws_json=$(${sway}/bin/swaymsg -t get_workspaces)
        focused_num=$(echo "$ws_json" | ${jq}/bin/jq -r '.[] | select(.focused) | .num')
        focused_output=$(echo "$ws_json" | ${jq}/bin/jq -r '.[] | select(.focused) | .output')
        main_output=$(echo "$ws_json" | ${jq}/bin/jq -r '.[] | select(.num==1) | .output')

        case "$focused_num" in
          6|7|8|9|10) ;;
          *) return ;;
        esac

        if [ -z "$main_output" ] || [ "$focused_output" = "$main_output" ]; then
          return
        fi

        ( sleep "$timeout" && prompt ) &
        timer_pid=$!
      }

      trap 'kill_timer; exit 0' INT TERM

      while true; do
        maybe_start_timer
        ${sway}/bin/swaymsg -t subscribe -m '["workspace"]' \
          | ${jq}/bin/jq --unbuffered -r 'select(.change=="focus") | .current.num' \
          | while read -r _num; do
              kill_timer
              maybe_start_timer
            done

        # swaymsg exits when sway reloads; reconnect after a brief pause.
        kill_timer
        sleep 2
      done
    '')
  ];
}
