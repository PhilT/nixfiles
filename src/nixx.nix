{
  lib
, stdenv
}:
let
  fs = lib.fileset;
  sourceFiles = ../lib;
in
stdenv.mkDerivation {
  name = "nixx";
  src = fs.toSource {
    root = ../.;
    fileset = sourceFiles;
  };
  installPhase = ''
    mkdir -p $out/lib
    mkdir -p $out/bin
    cp -v lib/*.rb $out/lib
    cp -v lib/nixx $out/bin
  '';
}