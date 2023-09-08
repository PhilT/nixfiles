{ config, pkgs, ... }:

{

  environment = {
    systemPackages = with pkgs; [
      envsubst
    ];
  };

  networking.extraHosts = ''
    127.0.0.1 www.carwow.local
    127.0.0.1 deals.carwow.local
    127.0.0.1 dealers.carwow.local
    127.0.0.1 quotes.carwow.local
  '';
}
