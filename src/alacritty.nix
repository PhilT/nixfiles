{ config, pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      alacritty
    ];

    etc = {
      "config/alacritty.yml" = {
        mode = "444";
        text = ''
        font:
          size: 8
        '';
      };
    };
  };

  system.userActivationScripts.alacritty = ''
    [ -e $XDG_CONFIG_HOME/alacritty.yml ] || ln -s /etc/config/alacritty.yml $XDG_CONFIG_HOME/alacritty.yml
  '';
}
