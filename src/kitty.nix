{ config, pkgs, lib, ... }:

with lib;

{
  options.programs.kitty = mkOption {
    type = types.submodule {
      options = {
        fontSize = mkOption {
          type = types.int;
          default = 10;
          description = "Set the font size in Kitty";
        };
      };
    };
  };

  config = {
    environment = {
      systemPackages = with pkgs; [
        kitty
        kitty-themes

        # Run kitty-themes to preview a list of themes. For some reason
        # --config-file-name doesn't work (Possibly because it can't write to the
        # main kitty.conf file). So, kitten-themes THEME NAME
        # will dump the theme into dotfiles/kitty-theme.conf
        (writeShellScriptBin "kitty-themes" ''
          if [ -z "$1" ]; then
            kitty +kitten themes
          else
            kitty +kitten themes --dump-theme $1 > $SRC/dotfiles/kitty-theme.conf
          fi
        '')
      ];

      sessionVariables = {
        KITTY_CONFIG_DIRECTORY = "/etc/config";
      };

      etc = {
        "config/kitty-theme.conf".source = ../dotfiles/kitty-theme.conf;
        "config/kitty.conf" = {
          mode = "444";
          text = ''
            include /etc/config/kitty-theme.conf
            font_family monospace
            font_size ${toString config.programs.kitty.fontSize}
            text_composition_strategy legacy
            copy_on_select clipboard
            strip_trailing_spaces always
            background_opacity 1.0
          '';
        };
      };
    };
  };
}