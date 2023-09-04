{ config, pkgs, ... }:

{

  environment = {
    systemPackages = with pkgs; [
      envsubst
    ];
  };
}
