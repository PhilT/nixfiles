{ config, pkgs, lib, ... }:

with lib;

{
  options.programs.alacritty = mkOption {
    type = types.submodule {
      options = {
        fontSize = mkOption {
          type = types.int;
          default = 10;
          description = "Set the font size in Alacritty";
        };
      };
    };
  };

  config = {
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
              size: ${toString config.programs.alacritty.fontSize}

            # Source: https://github.com/tyrannicaltoucan/vim-deep-space
            colors:
              # Default colors
              primary:
                background: '#1b202a'
                foreground: '#aab7cd'

              # Colors the cursor will use if `custom_cursor_colors` is true
              cursor:
                text: '#232936'
                cursor: '#51617d'

              # Normal colors
              normal:
                black: '#1b202a'
                red: '#b15e7c'
                green: '#709d6c'
                yellow: '#b5a262'
                blue: '#608cc3'
                magenta: '#8f72bf'
                cyan: '#56adb7'
                white: '#9aa7bd'

              # Bright colors
              bright:
                black: '#232936'
                red: '#b3785d'
                green: '#608d5c'
                yellow: '#c5a865'
                blue: '#507cb3'
                magenta: '#c47ebd'
                cyan: '#51617d'
                white: '#9aa7bd'
          '';
        };
      };
    };

    system.userActivationScripts.alacritty = ''
      [ -e $XDG_CONFIG_HOME/alacritty.yml ] || ln -s /etc/config/alacritty.yml $XDG_CONFIG_HOME/alacritty.yml
    '';
  };
}
