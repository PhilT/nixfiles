{ config, lib, pkgs, ... }: {
  imports = [
    ./dbgate.nix
    ./filemanager.nix
    ./firefox.nix
    ./keepmenu.nix
    ./kitty.nix
    ./thunderbird.nix
  ];

  environment.systemPackages = with pkgs; [
    (callPackage ./spectrum.nix {})
    (callPackage ./mxw.nix {})  # Glorious Model O tool
    qmk                         # Tool to configure QMK based keyboards
                                # (e.g. my GMMK 2)
    evince                      # PDF reader
    calibre                     # ebook manager
    libgourou                   # Needed to decrypt ACSM ebook files

    (writeShellScriptBin "de-acsm" ''
      pushd /tmp
      mkdir -p acsm
      cd acsm
      acsmdownloader -D /data/home/adept /data/downloads/URLLink.acsm
      [ -f /data/home/Adobe_PrivateLicenseKey--anonymous.der ] || acsmdownloader --export-private-key
      echo "Calibre->Plugins->Customize DeDRM->Manage Adobe Digital Editions Keys->Import Existing keyfiles"
      read -p "Press ENTER to add ePubs (Ensure Calibre is not running)"
      calibredb add *.epub
      read -p "Verify ebooks have been added to Calibre and can be read then press ENTER"
      rm *.epub
      popd
    '')

    # Audio/visual tools
    gimp3
    goxel                 # Voxel editor # FIXME: Broken package
    yad                   # GUI Dialog for Goxel
    imv                   # Image viewer
    inkscape
    mpv                   # Video player
    digikam               # Photo manager
    wf-recorder           # Screen recorder

    (writeShellScriptBin "record" ''
      name=$1
      wf-recorder -g "$(slurp)" --audio --file=/data/videos/screens/$name.mp4
    '')

    # Comms
    vesktop               # Discord replacement that works in native Wayland
    element-desktop       # Matrix chat client
    libreoffice
    slack
  ];


  systemd.tmpfiles.rules = [
    "d ${config.xdgConfigHome} - ${config.username} users -"
    "d ${config.xdgConfigHome}/calibre - ${config.username} users -"

    "L+ ${config.xdgConfigHome}/calibre/plugins - - - - ${config.persistedHomeDir}/calibre/plugins"
  ];
}