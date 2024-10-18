{ pkgs, ... }:
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
          pw_cache_period_min = 360
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

      #keepmenu
      # See if this fixes issues editing fields such as TOTP
      (keepmenu.overrideAttrs (oldAttrs: {
        version = "1.4.3";

        src = fetchFromGitHub {
          owner = "firecat53";
          repo = "keepmenu";
          rev = "develop";
          hash = "sha256-o2dQaysIpNG0CLvE4Jb/V5+LKsztfoOsMUKna6ymdg0=";
        };
        installCheckPhase = ''true''; # TODO: Remove once https://github.com/NixOS/nixpkgs/pull/328672 is merged
      }))
    ];
  };
}