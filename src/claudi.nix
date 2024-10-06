{ config, pkgs, ... }:

{
  imports = [
    ./kitty.nix
    ./audio.nix
  ];

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
    };
    settings.auto-optimise-store = true;
  };

  services = {
    # Only seems to work after opening PCManFM
    gvfs.enable = true; # Automount USB drives
  };

  environment = {
    sessionVariables = {
      # Duplicated in ./initialize
      DATA = "/data";
    };

    system.activationScripts.dataDir = ''
      [ -d "$DATA" ] || (mkdir -p $DATA && chown claudi:users $DATA)
    '';
  };

  hardware.bluetooth.enable = true;
  security.pam.services.gdm.enableGnomeKeyring = true;

  programs = {
    dconf.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-media-tags-plugin
        thunar-volman
      ];
    };

    chromium = {
      enable = true;
      extensions = [
        "cgbcahbpdhpcegmbfconppldiemgcoii" # ublock origin
        "cdkhedhmncjnpabolpjceohohlefegak" # Startpage privacy protection
      ];
      defaultSearchProviderEnabled = true;
      defaultSearchProviderSearchURL = "https://www.startpage.com/sp/search?query={searchTerms}";
      homepageLocation = "https://www.startpage.com";
      extraOpts = {
        "SpellcheckEnabled" = true;
        "SpellcheckLanguage" = [ "en-GB" ];
      };
    };
  };

  services = {
    blueman.enable = true;
    gnome.gnome-keyring.enable = true;

    xserver = {
      enable = true;
      excludePackages = with pkgs; [
        xterm
      ];
      displayManager = {
        defaultSession = "xfce";
        lightdm = {
          enable = true;
          greeters.slick = {
            enable = true;
            theme.name = "Zukitre-dark";
          };
        };
      };
      desktopManager.xfce.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    chromium
    deja-dup
    drawing
    elementary-xfce-icon-theme
    evince
    foliate
    font-manager
    gimp-with-plugins
    gnome.file-roller
    gnome.gnome-disk-utility
    inkscape-with-extensions
    libqalculate
    libreoffice
    orca
    qalculate-gtk
    wmctrl
    xclip
    xcolor
    xcolor
    xdo
    xdotool
    xfce.catfish
    xfce.gigolo
    xfce.orage
    xfce.xfburn
    xfce.xfce4-appfinder
    xfce.xfce4-clipman-plugin
    xfce.xfce4-cpugraph-plugin
    xfce.xfce4-dict
    xfce.xfce4-fsguard-plugin
    xfce.xfce4-genmon-plugin
    xfce.xfce4-netload-plugin
    xfce.xfce4-panel
    xfce.xfce4-pulseaudio-plugin
    xfce.xfce4-systemload-plugin
    xfce.xfce4-weather-plugin
    xfce.xfce4-whiskermenu-plugin
    xfce.xfce4-xkb-plugin
    xfce.xfdashboard
    xorg.xev
    xsel
    xtitle
    xwinmosaic
    zuki-themes
  ];
}