{ config, pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.slstatus.overrideAttrs (oldAttrs: {
      name = "slstatus-philt-custom";
      src = /data/code/slstatus;
    }))
  ];

  system.activationScripts.slstatus = ''
    /run/current-system/sw/bin/slstatus &
  '';
}
