{ config, pkgs, python3Packages, ... }:

{
  programs.ydotool.enable = true;
  programs.ydotool.group = "users";

  environment = {
    etc = {
      "config/keepmenu.ini" = {
        mode = "444";
        text = ''
          [dmenu]
          dmenu_command = tofi -c /etc/config/tofi.ini

          [dmenu_passphrase]
          obscure = True
          obscure_color = #555555

          [database]
          database_1 = /data/sync/HomeDatabase.kdbx
          keyfile_1 =
          pw_cache_period_min = 1
          autotype_default = {USERNAME}{TAB}{PASSWORD}{ENTER}
          terminal = kitty
          editor = nvim
          type_library = ydotool
        '';

      };
    };

    systemPackages = with pkgs; [
      (writeShellScriptBin "kp" "keepmenu -c /etc/config/keepmenu.ini $@")
      wl-clipboard

      (keepmenu.overrideAttrs (oldAttrs: {
        name = "keepmenu-philt-custom";
        src = /data/code/keepmenu;
        installCheckPhase = ''true'';
      }))
    ];
  };
}