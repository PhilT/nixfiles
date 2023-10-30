{ lib, stdenv, fetchurl, pkgs, which }:

let
  fl_version = "21.2.0.3842";
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
      echo "${fl_version}" > $WINEPREFIX/version
      wine start /unix OUT/installer/flstudio_installer.exe /S
    else
      # Run FL Studio
      echo "Running FL Studio ${fl_version}"
      echo "-------------------------------"
      cd "$WINEPREFIX/drive_c/Program Files/Image-Line/FL Studio 21"
      gamemoderun wine FL64.exe
    fi
  '';
in
stdenv.mkDerivation {
  pname = "flstudio";
  version = fl_version;

  src = fetchurl {
    url = "https://demodownload.image-line.com/flstudio/flstudio_win64_${fl_version}.exe";
    sha256 = "148c151c0fa7486c17a49cbf3b018d600278b72475b8b2f47087de57728bfb33";
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