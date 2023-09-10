{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "get_vol_perc" ''
      muted=$(pactl get-sink-mute 0 | sed 's/Mute: //')
      if [ "$muted" == "yes" ]; then
        volume="󰝟"
      else
        volume="󰕾 $(pactl get-sink-volume 0 | sed -En 's|.*/ +([0-9]+)% /.*|\1|p')"
      fi

      echo "$volume"
    '')

    (writeShellScriptBin "mute" ''
      pactl set-sink-mute @DEFAULT_SINK@ toggle
      get_vol_perc > .volumestatus
    '')

    (writeShellScriptBin "volup" ''
      pactl set-sink-volume @DEFAULT_SINK@ +5%
      get_vol_perc > .volumestatus
    '')

    (writeShellScriptBin "voldn" ''
      pactl set-sink-volume @DEFAULT_SINK@ -5%
      get_vol_perc > .volumestatus
    '')

    (slstatus.overrideAttrs (oldAttrs: {
      name = "slstatus-philt-custom";
      src = /data/code/slstatus;
    }))
  ];
}
