{ config, lib, pkgs, ... }:
{
  imports = [
    ./dbgate.nix
    ./filemanager.nix
    ./firefox.nix
    ./keepmenu.nix
    ./kitty.nix
    ./qutebrowser.nix
    ./thunderbird.nix
  ];

  environment.systemPackages = with pkgs; [
    #(callPackage ./studio.nix {})
    (callPackage ./spectrum.nix {})
    (callPackage ./mxw.nix {}) # Glorious Model O tool
    qmk                        # Tool to configure QMK based keyboards
                               # (e.g. my GMMK 2)

    # Audio/visual tools
    # gimp - Currently no Wayland until 3.0
    goxel                 # Voxel editor
    yad                   # GUI Dialog for Goxel
    imv                   # Image viewer
    inkscape
    mpv                   # Video player
    # simplescreenrecorder - Need to find a replacement for Wayland
    wineWowPackages.full  # Needed for FL Studdio installer

    # Comms
    vesktop               # Discord replacement that works in native Wayland
    element-desktop       # Matrix chat client
    libreoffice
    slack

  ];
}