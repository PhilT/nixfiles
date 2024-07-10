{ lib, stdenv, fetchurl, pkgs, which }:

# Scrape latest version from https://www.image-line.com/fl-studio-download/
let
  title = "FL Studio 2024";
  fl_version = "24.1.1.4239";
  flstudioRunner = pkgs.writeShellScriptBin "flstudio" ''
    export WINEPREFIX=$HOME/.wine/flstudio
    export WINEARCH=win64

    mkdir -p $WINEPREFIX

    # Install FL Studio (if version not installed)
    # Trigger build
    new_version="${fl_version}"
    existing_version=$([ -f "$WINEPREFIX/version" ] && cat $WINEPREFIX/version)

    if [ "$new_version" != "$existing_version" ]; then
      echo "Installing FL Studio ${fl_version}"
      echo "-------------------------------"
      rm -rf $WINEPREFIX    # Errors occur unless install dir is clean for the install
      mkdir -p $WINEPREFIX
      echo "${fl_version}" > $WINEPREFIX/version
      wine start /unix OUT/installer/flstudio_installer.exe /S

      # Install license RegKey
    else
      # Run FL Studio
      echo "Running FL Studio ${fl_version}"
      echo "-------------------------------"
      cd "$WINEPREFIX/drive_c/Program Files/Image-Line/${title}"
      wine FL64.exe
    fi
  '';
in
stdenv.mkDerivation {
  pname = "flstudio";
  version = fl_version;

  src = fetchurl {
    url = "https://demodownload.image-line.com/flstudio/flstudio_win64_${fl_version}.exe";
    sha256 = "sha256-sXC1Z4VzXurAZ0F8+N6YotF83njJFdFu3Z/b+X+Fr3c=";
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