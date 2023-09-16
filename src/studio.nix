{ lib, stdenv, fetchurl, pkgs, which }:

let
  flstudioRunner = pkgs.writeShellScriptBin "flstudio" ''
    #! ${stdenv.shell}
    export WINEPREFIX=$HOME/.wine/flstudio
    export WINEARCH=win64

    # Install FL Studio (if not installed)
    # Trigger build
    if [ ! -d $WINEPREFIX ]; then 
      mkdir -p $WINEPREFIX
      wine start /unix OUT/installer/flstudio_installer.exe /S
    fi

    # Run FL Studio
    cd "$WINEPREFIX/drive_c/Program Files/Image-Line/FL Studio 21"
    wine FL64.exe
  '';
in
stdenv.mkDerivation rec {
  pname = "flstudio";
  version = "21.1.1.3750";

  src = fetchurl {
    url = "https://support.image-line.com/redirect/flstudio_win_installer";
    sha256 = "lNMXr1KO0XFMH23yNHrPL1KsycPiK9TmaLve8zOZ89g=";
  };

  buildInputs = [ flstudioRunner which ];

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/installer
    mkdir -p $out/bin
    cp $src $out/installer/flstudio_installer.exe
    substitute $(which flstudio) $out/bin/flstudio --replace "OUT" "$out"
    chmod +x $out/bin/flstudio
  '';
}

