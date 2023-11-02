{ lib, stdenv, fetchzip, pkgs }:

let
  version = "4.2-beta3";
  platform = "Godot_v${version}_mono_linux";
  arch = "x86_64";
in
stdenv.mkDerivation {
  pname = "godot";
  version = version;

  src = fetchzip {
    url = "https://github.com/godotengine/godot-builds/releases/download/${version}/${platform}_${arch}.zip";
    sha256 = "2nT0b8tNS8md9q0G/NaZhMbhj3Imaofq35S0pXVZ9w4=";
  };

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/bin
    cp -r $src/GodotSharp $out/bin
    cp $src/${platform}.${arch} $out/bin/godot4
  '';
}