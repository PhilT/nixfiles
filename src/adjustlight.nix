{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [

    (writeShellScriptBin "adjustlight" ''
      level=$(light | sed -E 's/(.+)\..*/\1/')

      if [ "$1" = "up" ]; then
        direction=-A
        [ $level -ge "5" ] && amount=5 || amount=1
      else
        direction=-U
        [ $level -gt "5" ] && amount=5 || amount=1
      fi


      light $direction $amount
    '')
  ];
}