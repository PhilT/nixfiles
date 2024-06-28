{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [

    (writeShellScriptBin "adjustlight" ''
      if [ "$1" = "up" ]; then
        direction=-A
      else
        direction=-U
      fi

      light $direction 10
    '')
  ];
}