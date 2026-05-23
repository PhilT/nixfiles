{ config, lib, pkgs, ... }: {
  imports = [
    ./dbgate.nix
    ./filemanager.nix
    ./chromium.nix
    ./keepmenu.nix
    ./kitty.nix
    ./scripts/app-sync.nix
    ./scripts/move-window.nix
    ./scripts/start-apps.nix
    ./scripts/stop-machine.nix
  ];

  hardware.keyboard.zsa.enable = true;

  environment.systemPackages = with pkgs; [
    (callPackage ./spectrum.nix {})
    (callPackage ./mxw.nix {})  # Glorious Model O tool
    keymapp                     # Key viewer for ZSA Voyager
    evince                      # PDF reader
    calibre                     # ebook manager
    libgourou                   # Needed to decrypt ACSM ebook files

    (writeShellScriptBin "de-acsm" ''
      echo "Go to https://www.kobo.com/gb/en/library/books and download the ebook you want to decrypt"
      echo "It should be placed in /data/downloads/URLLink.acsm"
      read -p "Press ENTER to decrypt"
      mkdir -p /tmp/acsm
      cd /tmp/acsm
      acsmdownloader -D /data/home/adept /data/downloads/URLLink.acsm
      echo "Downloaded epub to $(pwd)"
      if [ ! -f /data/home/Adobe_PrivateLicenseKey--anonymous.der ]; then
        cd /data/home
        acsmdownloader -D /data/home/adept --export-private-key
        cd -
        echo "Calibre->Plugins->Customize DeDRM->Manage Adobe Digital Editions Keys->Import Existing keyfiles"
        echo "Select /data/home/Adobe_PrivateLicenseKey--anonymous.der"
      fi
      read -p "Press ENTER to add ePubs (Ensure Calibre is not running)"
      ADD_OUT=$(calibredb add *.epub)
      echo "$ADD_OUT"
      IDS=$(echo "$ADD_OUT" | grep "book ids:" | sed 's/.*book ids: //' | tr ', ' ' ' | tr -s ' ')
      echo "Verify ebooks have been added to Calibre and can be read"
      echo "Also connect Boox so ebooks can be copied to it"
      read -p "Press ENTER to export"
      EXPORT_TMP=$(mktemp -d)
      for ID in $IDS; do
        TITLE=$(calibredb list --fields title --search "id:=$ID" --separator '|' | tail -1 | cut -d'|' -f2- | xargs)
        AUTHOR=$(calibredb list --fields authors --search "id:=$ID" --separator '|' | tail -1 | cut -d'|' -f2- | xargs)
        SAFE_AUTHOR=$(echo "$AUTHOR" | tr '/:\\' '-' | sed 's/-\+/-/g')
        SAFE_TITLE=$(echo "$TITLE" | tr '/:\\' '-' | sed 's/-\+/-/g')
        DEST="/data/books/Fiction/$SAFE_AUTHOR"
        mkdir -p "$DEST"
        calibredb export --dont-save-cover --dont-write-opf --single-dir --to-dir "$EXPORT_TMP" "$ID"
        mv "$EXPORT_TMP"/*.epub "$DEST/$SAFE_TITLE.epub"
        echo "Exported: $DEST/$SAFE_TITLE.epub"
        if adb devices | grep -q "device$"; then
          adb shell "mkdir -p '/sdcard/Books/Fiction/$SAFE_AUTHOR'"
          adb push "$DEST/$SAFE_TITLE.epub" "/sdcard/Books/Fiction/$SAFE_AUTHOR/$SAFE_TITLE.epub"
          echo "Copied to Boox: Books/Fiction/$SAFE_AUTHOR/$SAFE_TITLE.epub"
        else
          echo "Boox not connected, skipping device copy"
        fi
      done

      rm -rf "$EXPORT_TMP"
      rm *.epub
      rm /data/downloads/URLLink.acsm
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