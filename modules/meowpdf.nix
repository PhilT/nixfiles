{ pkgs, ... }:

pkgs.rustPlatform.buildRustPackage (finalAttrs: {
  pname = "meowpdf";
  version = "1.3.0";

  src = pkgs.fetchFromGitHub {
    owner = "PhilT";
    repo = "MeowPDF";
    rev = "02a5e1d51f9fd1323690fbffe012c9d9bf279698";
    hash = "sha256-rBaZCSkzmbTzbBH/D2AEK77hv697k/sNZUTGjO2DuUU=";
  };

  cargoHash = "sha256-AekHfI+r/eRCfwYAnzrjRdTsXNAhDe6e+jNESgtsHQY=";

  nativeBuildInputs = [
    pkgs.pkg-config
    pkgs.rustPlatform.bindgenHook
  ];

  meta = {
    description = "PDF viewer for the Kitty terminal with GUI-like usage and Vim-like keybindings written in Rust";
    homepage = "https://github.com/PhilT/MeowPDF";
    license = pkgs.lib.licenses.mit;
    mainProgram = "meowpdf";
    platforms = pkgs.lib.platforms.linux;
  };
})
