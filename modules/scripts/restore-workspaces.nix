{ config, lib, pkgs, ... }:
let
  ws = import ../sway/workspaces.nix;

  resolveOutput = key: ws.outputs.${key};
  swapKey = key: if key == "primary" then "secondary" else "primary";

  moveLinesFor = assignments: lib.concatStringsSep "\n" (lib.mapAttrsToList (num: outputKey:
    let output = resolveOutput outputKey;
    in ''    swaymsg "workspace ${num}; move workspace to output ${output}"''
  ) assignments);

  normalMoveCommands  = moveLinesFor ws.assignments;
  swappedMoveCommands = moveLinesFor (lib.mapAttrs (_: swapKey) ws.assignments);

  # Lowest workspace number per output key, used to ensure each output
  # has its default workspace visible at startup. Sway only auto-creates
  # one workspace per output on init and may pick the "wrong" one when
  # our swap override fights with the static fallback list.
  lowestNumForOutput = assignments: outputKey:
    let
      nums = lib.attrNames (lib.filterAttrs (_: k: k == outputKey) assignments);
      sorted = lib.sort (a: b: (lib.toInt a) < (lib.toInt b)) nums;
    in lib.head sorted;

  defaultsFor = assignments: lib.concatStringsSep "\n" (map (k:
    ''    swaymsg "workspace number ${lowestNumForOutput assignments k}"''
  ) [ "primary" "secondary" ]);

  normalDefaultCommands  = defaultsFor ws.assignments;
  swappedDefaultCommands = defaultsFor (lib.mapAttrs (_: swapKey) ws.assignments);

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

      focused=$(${sway}/bin/swaymsg -t get_workspaces \
        | ${jq}/bin/jq -r '.[] | select(.focused) | .num')

      # If the swap override file is present, apply the swapped layout
      if [ -s "$HOME/.config/sway/overrides/workspaces.conf" ]; then
  ${swappedMoveCommands}
  ${swappedDefaultCommands}
      else
  ${normalMoveCommands}
  ${normalDefaultCommands}
      fi

      ${sway}/bin/swaymsg "workspace number $focused"

      ${libnotify}/bin/notify-send "Workspaces restored"
    '')

    (writeShellScriptBin "sway-output-listener" ''
      while true; do
        ${sway}/bin/swaymsg -t subscribe -m '["output"]' | while read -r event; do
          # Ignore wallpaper changes (flag file set by nixx wallpaper --apply)
          [ -f /tmp/sway-wallpaper-changing ] && continue

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
