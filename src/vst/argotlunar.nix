{
  lib
, stdenv
, fontconfig
, alsa-lib
, cmake
, fetchurl
, makeWrapper
, gnutar
, freetype
, xorg
, libGL
, zenity
}:
let
  basename = "argotlunar-2.06-linux_64";
  libname = "argotlunar.so";
in
stdenv.mkDerivation rec {
  pname = "argotlunar";
  version = "1.0";

  src = /data/studio/vst/${basename}.tar.gz;
  nativeBuildInputs = [ makeWrapper gnutar ];
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
    tar -xvzf $src
  '';

  installPhase = ''
    mkdir -p $out/lib/vst
    cp '${basename}/${libname}' $out/lib/vst/
  '';

  postFixup = ''
    patchelf --set-rpath "${lib.makeLibraryPath buildInputs}" $out/lib/vst/'${libname}'
  '';
}