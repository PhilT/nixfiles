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
      (writeShellScriptBin "kp" "keepmenu")

      dmenu
      fd                  # Alternative to find
      feh
      fsautocomplete
      dbeaver             # SQL client
      flameshot           # Screnshot tool
      gimp
      inkscape
      keepassxc
      keepmenu
      pcmanfm
      pulseaudio
      ripgrep
      slack
      surf
      unzip
      whatsapp-for-linux
      xclip               # Used by Neovim among other things for copy/paste from/to system clipboard
      zip
    ];
  };
}
