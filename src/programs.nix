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

  system.userActivationScripts.background = ''
    [ -f $HOME/.fehbg ] && $HOME/.fehbg
  '';

  environment = {
    systemPackages = with pkgs; [
      (writeShellScriptBin "kp" ''keepmenu'')

      dmenu
      feh
      fsautocomplete
      gimp
      inkscape
      keepassxc
      keepmenu
      links2
      nerdfonts
      pcmanfm
      pulseaudio
      ripgrep
      runningx
      surf
      unzip
      whatsapp-for-linux
      zip
    ];
  };
}
