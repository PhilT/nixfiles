{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [

    (writeShellScriptBin "adjustlight" ''
      if [ "$1" = "up" ]; then
        direction=-A
      else
        direction=-U
      fi

      level=$(light | sed -E 's/(.+)\..*/\1/')
      if [ $level -gt "5" ]; then
        amount=5
      else
        amount=1
      fi

      light $direction $amount
    '')
  ];
}