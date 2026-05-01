# CLI for configuring Glorious Model O Wireless Mouse
# Configure various settings (e.g. polling  rate, colors, brightness)
# Only works while plugged in via USB
# Examples:
#  mxw config led-brightness 50
#  mxw config led-effect solid 00eeff
{ pkgs, ... }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "mxw";
  version = "0.1.3";
  cargoHash = "sha256-mlOfRMrb1Cia4ezFh60LluoQxBVBaTkPl2F+h8dHalw=";
  useCargoVendor = true;

  buildInputs = with pkgs; [ libudev-zero ];
  nativeBuildInputs = with pkgs; [ pkg-config libudev-zero ];

  src = pkgs.fetchFromGitHub {
    owner = "dxbednarczyk";
    repo = "mxw";
    rev = "6978ea2355c47961e838cbbc99d2853ee354396f";
    sha256 = "sha256-07KLWBxDU0pXlq5afkJRebSWbQl+VfoHKK19OLnwW7g=";
  };
}