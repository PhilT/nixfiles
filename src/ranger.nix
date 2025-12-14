{ config, pkgs, ... }: {
  services = {
    # Automount USB drives
    gvfs.enable = true;
    udisks2.enable = true;
    devmon.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      shared-mime-info      # Recognise different file types
      ranger                # Terminal file manager
      android-tools         # Used to sync with phone
      adbfs-rootless

      # Supporting packages for ranger
      ffmpeg                # View videos
      file                  # Determine file type
      imagemagick_light     # Rotate images
      librsvg               # View SVGs
      bat                   # Syntax highlighting for cat

      # Connect to my phone via adb and use ranger to view files.
      # Extract the IP address of Suuno (also used in src/common.nix)
      (writeShellScriptBin "ranger-adb" ''
        sudo mkdir -p /mnt/android
        sudo chown phil:users /mnt/android
        adb connect 192.168.1.205:5555
        if [ "$?" = "0" ]; then
          echo "Connected to Android device"
        else
          echo "Failed to connect to Android device"
          echo "Enter port number (Settings->Developer Options->Wireless Debugging)"
          port=$(read)
          adb connect 192.168.1.205:$port
          adb tcpip 5555
          adb connect 192.168.1.205:5555
          if $?; then
            echo "Connected to Android device"
          else
            echo "Still failing to connect to Android device"
            exit 1
          fi
        fi
        adbfs /mnt/android
        ranger /mnt/android
        fusermount -u /mnt/android
      '')
    ];

    etc = {
      "config/ranger/rc.conf" = {
        mode = "444";
        text = ''
          set preview_images_method kitty
        '';
      };

      "config/ranger/rifle.conf" = {
        mode = "444";
        text = ''
          # Text files in terminal editor
          ext json|txt|md|xml|yaml|yml|toml|conf|cfg|ini|log|nix = "$EDITOR" -- "$@"
          mime ^text = "$EDITOR" -- "$@"

          # Use termpdf to view PDFs
          ext pdf = "termpdf.py" "$@"
          mime ^application/pdf = "termpdf.py" "$@"

          # Fallback to opening files with xdg-open
          # FIXME: This is disabled as it's opening Calibre at the moment
          # else = xdg-open "$@"
        '';
      };
    };
  };

  # https://www.freedesktop.org/software/systemd/man/tmpfiles.d.html
  # man tmpfiles.d
  systemd.tmpfiles.rules = [
    "d ${config.xdgConfigHome} - ${config.username} users -"
    "d ${config.xdgConfigHome}/ranger - ${config.username} users -" # For some reason ranger needs write access to this dir

    "L+ ${config.xdgConfigHome}/ranger/rc.conf - - - - /etc/config/ranger/rc.conf"
    "L+ ${config.xdgConfigHome}/ranger/rifle.conf - - - - /etc/config/ranger/rifle.conf"
  ];
}