{
  lib
, stdenv
, fontconfig
, alsa-lib
, cmake
, fetchurl
, makeWrapper
, unzip
, freetype
, xorg
, libGL
, zenity
}:
let vst_path = "OT P1ANO S.so";
in
stdenv.mkDerivation rec {
  pname = "ot_piano_s";
  version = "1.0";

  src = /data/studio/vst/OT_P1ANO_S.zip;
  nativeBuildInputs = [ makeWrapper unzip ];
  buildInputs = [
    alsa-lib
    freetype
    stdenv.cc.cc.lib
    libGL
    fontconfig
    xorg.libICE
    xorg.libSM
    xorg.libX11
    xorg.libXext
  ];

  unpackPhase = ''
    unzip $src
  '';

  installPhase = ''
    mkdir -p $out/lib/vst
    cp '${vst_path}' $out/lib/vst/
  '';

  postFixup = ''
    patchelf --set-rpath "${lib.makeLibraryPath buildInputs}" $out/lib/vst/'${vst_path}'
  '';
}