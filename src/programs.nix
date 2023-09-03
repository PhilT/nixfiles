{ config, pkgs, ... }:

{
  programs = {
    # xautolock also added in services
    slock.enable = true;

    # Autorun nix-shell when entering a dir with a shell.nix (e.g. a .NET project)
    direnv.enable = true;

    bash.shellAliases = {
      ss = "feh -Z -F -D 15";
    };

    chromium = {
      enable = true;
      extensions = [
        "cgbcahbpdhpcegmbfconppldiemgcoii" # ublock origin
        "cdkhedhmncjnpabolpjceohohlefegak" # Startpage privacy protection
      ];
      defaultSearchProviderSearchURL = "https://www.startpage.com/sp/search?query={searchTerms}&cat=web&pl=chrome";
      homepageLocation = "https://startpage.com";
    };
  };

  environment = {
    systemPackages = with pkgs; [
      (writeShellScriptBin "s" ''chromium --force-dark-mode https://www.startpage.com/sp/search?query="$@" &'')

      alacritty
      chromium
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

  system.userActivationScripts.alacritty = ''
    [ -e $XDG_CONFIG_HOME/alacritty.yml ] || ln -s /etc/config/alacritty.yml $XDG_CONFIG_HOME/alacritty.yml
  '';
}
