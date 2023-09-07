{ config, pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.slstatus.overrideAttrs (oldAttrs: {
      name = "slstatus-philt-custom";
      src = /data/code/slstatus;
    }))
  ];
}
