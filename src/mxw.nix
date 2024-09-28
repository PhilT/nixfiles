# CLI for configuring Glorious Model O Wireless Mouse
# Configure various settings (e.g. polling  rate, colors, brightness)
# Examples:
#  mxw config led-brightness 50
#  mxw config led-effect solid 00eeff
{ pkgs, ... }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "mxw";
  version = "0.1.2";
  cargoHash = "sha256-ESEIqP5dNDj9CkUSWNumSlvSGEfegTD517QN++0zrEg=";

  buildInputs = with pkgs; [ libudev-zero ];
  nativeBuildInputs = with pkgs; [ pkg-config libudev-zero ];

  src = pkgs.fetchFromGitHub {
    owner = "dxbednarczyk";
    repo = "mxw";
    rev = "master";
    sha256 = "sha256-HF4VH6dVI+2hQy6u16pxfmBCGhV9rwZNcYW+ASr74fw=";
  };
}