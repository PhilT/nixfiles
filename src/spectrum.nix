{
  lib
, stdenv
, alsa-lib
, ffmpeg
, cmake
, fetchFromGitHub
, fftw
, libxmlxx
, libxmlxx3
, curl
, pkg-config
, pcre2
}:
let
  name = "spectrum";
  ftxui_git_url = "https://github.com/ArthurSonzogni/ftxui";
  ftxui_git_tag = "7de4f8683d530ff5573483f40b17df4b3c6ed736";
in
stdenv.mkDerivation {
  pname = name;
  version = "0.0.1";

  srcs = [
    (fetchFromGitHub {
      owner = "v1nns";
      repo = name;
      rev = "main";
      name = name;
      sha256 = "7y+45YTJYSbLOeqw0vy3nQ+N5s+q4kzbtcyd/DnlMA0=";
    })
    (fetchFromGitHub {
      owner = "ArthurSonzogni";
      repo = "ftxui";
      rev = ftxui_git_tag;
      name = "ftxui";
      sha256 = "cnknJ+RTJ1R7OF1+x94Y8lomIAd2hF6PIEX8sUx0g3k=";
    })
  ];

  sourceRoot = name;
  nativeBuildInputs = [ cmake pkg-config pcre2 ];
  buildInputs = [ fftw libxmlxx libxmlxx3 curl alsa-lib ffmpeg libxmlxx3 ];

  patchPhase = ''
    substituteInPlace src/CMakeLists.txt --replace "GIT_REPOSITORY ${ftxui_git_url}" "SOURCE_DIR ../../../ftxui" --replace "GIT_TAG ${ftxui_git_tag})" ")"
  '';

  configurePhase = ''
    cmake -S . -B build
  '';

  buildPhase = ''
    cmake --build build
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp -r build/src/${name} $out/bin
  '';
}