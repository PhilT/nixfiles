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
  cargoHash = "sha256-yNoUnfxU3+N7hWoDxxJ3Nz6Qk8YvThqDCARFNBfS/Es=";
  useCargoVendor = true;

  buildInputs = with pkgs; [ libudev-zero ];
  nativeBuildInputs = with pkgs; [ pkg-config libudev-zero ];

  src = pkgs.fetchFromGitHub {
    owner = "dxbednarczyk";
    repo = "mxw";
    rev = "master";
    sha256 = "sha256-qqOEN3f4r/x3KS8MaLEApx1l0B9snX6SZyVndYGU8xw=";
  };
}