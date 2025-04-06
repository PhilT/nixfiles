# CLI for configuring Glorious Model O Wireless Mouse
# Configure various settings (e.g. polling  rate, colors, brightness)
# Examples:
#  mxw config led-brightness 50
#  mxw config led-effect solid 00eeff
{ pkgs, ... }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "mxw";
  version = "0.1.2";
  cargoHash = "sha256-+7/pJfC9I+ZFhBi+X7/1EIzUVHaScvrElnuFPP+4rLM=";
  useCargoVendor = true;

  buildInputs = with pkgs; [ libudev-zero ];
  nativeBuildInputs = with pkgs; [ pkg-config libudev-zero ];

  src = pkgs.fetchFromGitHub {
    owner = "dxbednarczyk";
    repo = "mxw";
    rev = "master";
    sha256 = "sha256-0my+kGgN5MchWvZP2vtntHAm9Wbc6EFGYQRc1nM3a3E=";
  };
}