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
}: stdenv.mkDerivation rec {
  pname = "sala";
  version = "1.0";

  src = fetchurl {
    url = "https://www.audiopluginsforfree.com/wp-content/uploads/2025/04/sala-v1-0.zip";
    sha256 = "sha256-MbDx0aUNq1n3BHXMWpt4Xt/R8svzeu1oMPeQu0cXr9k=";
  };

  nativeBuildInputs = [ makeWrapper unzip ];
  buildInputs = [
    alsa-lib
    freetype
    stdenv.cc.cc.lib
    fontconfig
  ];

  unpackPhase = ''
    unzip $src
    unzip Sala-v1_0-Linux.zip
  '';

  installPhase = ''
    mkdir -p $out/lib/vst3
    cp -r Sala.vst3 $out/lib/vst3/
  '';

  postFixup = ''
    patchelf --set-rpath "${lib.makeLibraryPath buildInputs}" $out/lib/vst3/Sala.vst3/Contents/x86_64-linux/Sala.so
  '';
}