{ config, pkgs, python3Packages, ... }:

let newKeepmenu = pkgs.keepmenu.overrideAttrs (old: {
  src = python3Packages.fetchPypi {
    pname = "keepmenu";
    version = "1.4.0";
    #sha256 = "SeVNtONH1bn2hb2pBOVM3Oafrb+jARgfvRe7vUu6Gto=";
  };
});
in
{
  environment = {
    etc."config/keepmenu.ini" = {
      mode = "444";
      text = ''
        [dmenu]
        dmenu_command = "dmenu_run -i"

        [dmenu_passphrase]
        obscure = True
        obscure_color = #555555

        [database]
        database_1 = /data/sync/HomeDatabase.kdbx
        keyfile_1 =
        pw_cache_period_min = 360
        autotype_default = {USERNAME}{TAB}{PASSWORD}{ENTER}
        terminal = alacritty
        editor = nvim
      '';
    };

    systemPackages = with pkgs; [
      (writeShellScriptBin "kp" "keepmenu -c /etc/config/keepmenu.ini $@")
      (dmenu.overrideAttrs (oldAttrs: {
        name = "dmenu-philt-custom";
        src = /data/code/dmenu;
      }))

      keepmenu
    ];
  };
}
