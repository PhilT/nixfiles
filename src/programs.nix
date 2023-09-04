{ config, pkgs, ... }:

{
  programs = {
    # xautolock also added in services
    slock.enable = true;

    # Autorun nix-shell when entering a dir with a shell.nix (e.g. a .NET project)
    direnv.enable = true;

    bash.shellAliases = {
      ss = "feh -Z -F -D 15";
      invoice = "nix-shell $CODE/sheetzi/shell.nix --command $CODE/sheetzi/invoice";
    };
  };

  environment = {
    systemPackages = with pkgs; [
      dmenu
      feh
      fsautocomplete
      gimp
      inkscape
      keepassxc
      keepmenu
      neomutt
      pcmanfm
      pulseaudio
      ripgrep
      unzip
      zip
    ];
  };
}
