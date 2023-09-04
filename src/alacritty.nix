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
        window:
          opacity: 0.6
        font:
          size: 8
          family: hack
        '';
      };
    };
  };

  system.userActivationScripts.alacritty = ''
    [ -e $XDG_CONFIG_HOME/alacritty.yml ] || ln -s /etc/config/alacritty.yml $XDG_CONFIG_HOME/alacritty.yml
  '';
}
