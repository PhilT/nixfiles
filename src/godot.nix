{ lib, stdenv, fetchzip, pkgs }:

let
  version = "4.2.1-stable";
  platform = "Godot_v${version}_mono_linux";
  arch = "x86_64";
in
stdenv.mkDerivation {
  pname = "godot";
  version = version;

  src = fetchzip {
    url = "https://github.com/godotengine/godot-builds/releases/download/${version}/${platform}_${arch}.zip";
    sha256 = "OohkRD3vlUGShzFs9TzbSdOJN5zuaOdRIZJ5UdcEm2Q=";
  };

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/bin
    cp -r $src/GodotSharp $out/bin
    cp $src/${platform}.${arch} $out/bin/godot4
  '';
}