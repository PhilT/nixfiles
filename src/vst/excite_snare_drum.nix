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
, xcb-util-cursor
, libxkbcommon
, glib
, cairo
, pango
, expat
}:
let
  vst_path = "excite_snare_drum.so";
  vst_folder = "excite_snare_drum.vst3";
  outDir = "$out/lib/vst3";
  presetDir = "$out/share/vst3/presets";
in
stdenv.mkDerivation rec {
  pname = "excite_snare_drum";
  version = "1.0";

  src = /data/studio/vst/excite_snare_drum-Linux.zip;
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
    xorg.libxcb
    xorg.xcbutil
    xcb-util-cursor
    libxkbcommon
    glib
    cairo
    pango
    expat
  ];

  unpackPhase = ''
    unzip $src
  '';

  installPhase = ''
    mkdir -p ${outDir}
    cp -r '${vst_folder}' ${outDir}
    mkdir -p ${presetDir}
    cp -r Presets/* ${presetDir}
  '';

  postFixup = ''
    patchelf --set-rpath "${lib.makeLibraryPath buildInputs}" ${outDir}'/${vst_folder}/Contents/x86_64-linux/${vst_path}'
  '';
}