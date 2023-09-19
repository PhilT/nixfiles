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
    systemPackages = with pkgs; [
      (callPackage ./studio.nix {})

      #deadbeef-with-plugins # Music player
      cmus                  # Terminal based music player
      fd                    # Alternative to find
      feh
      fsautocomplete
      discord
      flameshot             # Screnshot tool
      gimp
      inkscape
      keepassxc
      libreoffice
      lxde.lxmenu-data      # List apps to run in PCManFM
      pcmanfm
      pulseaudio
      ripgrep
      shared-mime-info      # Recognise different file types
      slack
      surf
      unzip
      vengi-tools           # Voxel tools including VoxEdit
      whatsapp-for-linux
      wineWowPackages.full  # Needed for FL Studdio installer
      xclip                 # Used by Neovim among other things for copy/paste from/to system clipboard
      xdotool               # For keepmenu
      pinentry
      zip
    ];
  };
}
