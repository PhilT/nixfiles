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

          # Colors (One Dark)
          colors:
            # Default colors
            primary:
              background: '0x1e2127'
              foreground: '0xabb2bf'

            # Normal colors
            normal:
              black:   '0x1e2127'
              red:     '0xe06c75'
              green:   '0x98c379'
              yellow:  '0xd19a66'
              blue:    '0x61afef'
              magenta: '0xc678dd'
              cyan:    '0x56b6c2'
              white:   '0xabb2bf'

            # Bright colors
            bright:
              black:   '0x5c6370'
              red:     '0xe06c75'
              green:   '0x98c379'
              yellow:  '0xd19a66'
              blue:    '0x61afef'
              magenta: '0xc678dd'
              cyan:    '0x56b6c2'
              white:   '0xffffff'
        '';
      };
    };
  };

  system.userActivationScripts.alacritty = ''
    [ -e $XDG_CONFIG_HOME/alacritty.yml ] || ln -s /etc/config/alacritty.yml $XDG_CONFIG_HOME/alacritty.yml
  '';
}
