{ config, pkgs, lib, fetchFromGitHub, ... }:

with lib;

let newKitty = pkgs.kitty.overrideAttrs (old: {
  version = "0.30.0";
  src = fetchFromGitHub {
    rev = "refs/tags/v0.30.0";
  };
});
in
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

        (writeShellScriptBin "kitty-themes" ''
          kitty +kitten themes --config-file-name $SRC/dotfiles/kitty-theme.conf
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
            font_family UbuntuMono Nerd Font Mono
            font_size ${toString config.programs.kitty.fontSize}
            text_composition_strategy legacy
            copy_on_select clipboard
            strip_trailing_spaces always
            background_opacity 0.6
          '';
        };
      };
    };
  };
}
