{
  lib
, stdenv
}:
let
  fs = lib.fileset;
  sourceFiles = lib.fileset.unions [../lib ../config];
in
stdenv.mkDerivation {
  name = "nixx";
  src = fs.toSource {
    root = ../.;
    fileset = sourceFiles;
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{lib,config,bin}

    cp -v lib/*.rb $out/lib
    cp -v config/*.yml* $out/config
    cp -v config/master.key $out/config
    cp -v lib/nixx $out/bin

    runHook postInstall
  '';
}