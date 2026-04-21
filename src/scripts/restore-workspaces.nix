{ config, lib, pkgs, ... }:
let
  ws = import ../sway/workspaces.nix;

  # Resolve output key to actual output name
  resolveOutput = key: ws.outputs.${key};

  # Build workspace move commands for restore-workspaces
  workspaceMoveCommands = lib.concatStringsSep "\n" (lib.mapAttrsToList (num: outputKey:
    let output = resolveOutput outputKey;
    in ''    swaymsg "workspace ${num}; move workspace to output ${output}"''
  ) ws.assignments);

  # Build floating window resize + reposition commands
  floatingWindowCommands = lib.concatStringsSep "\n" (map (fw: ''
    swaymsg "[app_id=${fw.appId}] move to output ${resolveOutput "primary"}"
    swaymsg "[app_id=${fw.appId}] resize set ${toString fw.width} ${toString fw.height}"
    swaymsg "[app_id=${fw.appId}] move absolute position ${toString fw.x} ${toString fw.y}"''
  ) ws.floatingWindows);

  # Build restore-only window commands (resize without repositioning)
  restoreWindowCommands = lib.concatStringsSep "\n" (map (rw:
    let
      criteria = "[app_id=\"${rw.appId}\" title=\"${rw.title}\"]";
    in ''    swaymsg '${criteria} resize set ${toString rw.width} ${toString rw.height}' ''
  ) (ws.restoreWindows or []));

  # Expected output names for the poll loop
  expectedOutputs = lib.unique (lib.mapAttrsToList (_: key: resolveOutput key) ws.assignments);
  expectedOutputChecks = lib.concatStringsSep " && " (map (o:
    ''echo "$outputs" | grep -q '${o}' ''
  ) expectedOutputs);
in
{
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "restore-workspaces" ''
      # Wait for expected outputs to be connected (up to 15s)
      for i in $(seq 1 15); do
        outputs=$(${sway}/bin/swaymsg -t get_outputs | ${jq}/bin/jq -r '.[].name')
        if ${expectedOutputChecks}; then
          break
        fi
        sleep 1
      done

      # Save currently focused workspace
      focused=$(${sway}/bin/swaymsg -t get_workspaces | ${jq}/bin/jq -r '.[] | select(.focused) | .num')

      # Move each workspace to its correct output
  ${workspaceMoveCommands}

      # Resize and reposition floating windows
  ${floatingWindowCommands}

      # Resize restore-only windows
  ${restoreWindowCommands}

      # Restore focus
      ${sway}/bin/swaymsg "workspace $focused"

      ${libnotify}/bin/notify-send "Workspaces restored"
    '')

    (writeShellScriptBin "sway-output-listener" ''
      while true; do
        ${sway}/bin/swaymsg -t subscribe -m '["output"]' | while read -r event; do
          # Ignore background-only changes (e.g. from swaymsg output ... background ...)
          change=$(echo "$event" | ${jq}/bin/jq -r '.change // empty')
          [ "$change" = "bg" ] && continue

          # Debounce: wait for outputs to settle, skip redundant events
          sleep 2

          # Drain any queued events
          while read -r -t 0.1 _; do :; done

          restore-workspaces
        done

        # Reconnect after sway reload (swaymsg exits when sway restarts)
        sleep 2
      done
    '')
  ];
}
