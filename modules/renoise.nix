{
  lib,
  stdenv,
  writeScript,
  alsa-lib,
  fetchurl,
  libjack2,
  libx11,
  libxcursor,
  libxext,
  libxinerama,
  libxrandr,
  libxtst,
  mpg123,
  pipewire,
  releasePath ? null,
}:

let
  platforms = {
    x86_64-linux = {
      archSuffix = "x86_64";
      hash = "sha256-RfOhcllmwX3Cy6ywIYjIC+kUX6rXkd+PM9wKj+fCuts=";
    };
    aarch64-linux = {
      archSuffix = "arm64";
      hash = "sha256-1bo7/srdQ5M5mzXpL76Bkt1Gt9EhbW8ktLLPvOcFu5U=";
    };
  };

in
stdenv.mkDerivation rec {
  pname = "renoise";
  version = "3.5.4";

  src =
    if releasePath != null then
      releasePath
    else
      let
        platform = platforms.${stdenv.system} or (throw "unsupported system ${stdenv.hostPlatform.system}");
        urlVersion = lib.replaceStrings [ "." ] [ "_" ] version;
      in
      fetchurl {
        urls = [
          "https://files.renoise.com/demo/Renoise_${urlVersion}_Demo_Linux_${platform.archSuffix}.tar.gz"
          "https://files.renoise.com/demo/archive/Renoise_${urlVersion}_Demo_Linux_${platform.archSuffix}.tar.gz"
        ];
        hash = platform.hash;
      };

  buildInputs = [
    alsa-lib
    libjack2
    libx11
    libxcursor
    libxext
    libxinerama
    libxrandr
    libxtst
    pipewire
  ];

  installPhase = ''
    cp -r Resources $out

    mkdir -p $out/lib/

    cp renoise $out/renoise

    for path in ${toString buildInputs}; do
      ln -s $path/lib/*.so* $out/lib/
    done

    ln -s ${lib.getLib stdenv.cc.cc}/lib/libstdc++.so.6 $out/lib/

    mkdir $out/bin
    ln -s $out/renoise $out/bin/renoise

    # Desktop item
    mkdir -p $out/share/applications
    cp -r Installer/renoise.desktop $out/share/applications/renoise.desktop

    # Desktop item icons
    mkdir -p $out/share/icons/hicolor/{48x48,64x64,128x128}/apps
    cp Installer/renoise-48.png $out/share/icons/hicolor/48x48/apps/renoise.png
    cp Installer/renoise-64.png $out/share/icons/hicolor/64x64/apps/renoise.png
    cp Installer/renoise-128.png $out/share/icons/hicolor/128x128/apps/renoise.png
  '';

  postFixup = ''
    patchelf \
      --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
      --set-rpath ${mpg123}/lib:$out/lib \
      $out/renoise

    for path in $out/AudioPluginServer*; do
      patchelf \
        --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
        --set-rpath $out/lib \
        $path
    done

    substituteInPlace $out/share/applications/renoise.desktop \
      --replace Exec=renoise Exec=$out/bin/renoise
  '';

  meta = {
    description = "Modern tracker-based DAW";
    homepage = "https://www.renoise.com/";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ uakci ];
    platforms = lib.attrNames platforms;
    mainProgram = "renoise";
  };
}
