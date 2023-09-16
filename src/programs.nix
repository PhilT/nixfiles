{ config, pkgs, ... }:

{
  programs = {
    # `j term` cd quickly
    autojump.enable = true;

    # Autorun nix-shell when entering a dir with a shell.nix (e.g. a .NET project)
    direnv.enable = true;

    # xautolock also added in services
    slock.enable = true;

    # Starship - Highly configurable shell prompt
    starship.enable = true;

    bash.shellAliases = {
      ss = "feh -Z -F -D 15";
      invoice = "nix-shell $CODE/sheetzi/shell.nix --command $CODE/sheetzi/invoice";
    };
  };


  environment = {
    etc."config/keepmenu.ini" = {
      mode = "444";
      text = ''
        [dmenu]
        dmenu_command = dmenu

        [dmenu_passphrase]
        obscure = True
        obscure_color = #222222

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
      (writeShellScriptBin "kp" "keepmenu -c /etc/config/keepmenu.ini")

      #deadbeef-with-plugins # Music player
      cmus                # Terminal based music player
      dmenu
      fd                  # Alternative to find
      feh
      fsautocomplete
      dbeaver             # SQL client
      discord
      flameshot           # Screnshot tool
      gimp
      inkscape
      keepassxc
      keepmenu
      libreoffice
      lxde.lxmenu-data    # List apps to run in PCManFM
      pcmanfm
      pulseaudio
      ripgrep
      shared-mime-info    # Recognise different file types
      slack
      surf
      unzip
      vengi-tools         # Voxel tools including VoxEdit
      whatsapp-for-linux
      xclip               # Used by Neovim among other things for copy/paste from/to system clipboard
      zip
    ];
  };
}
