{
  config
, stdenv
, fetchFromGitHub
, meson
, ninja
, dbus
, pkg-config
}:
let
  name = "iio-hyprland";
in
stdenv.mkDerivation {
  name = name;

  src = fetchFromGitHub {
    owner = "jeanSchoeller";
    repo = name;
    rev = "master";
    name = name;
    sha256 = "sha256-JUYuk1MTyK/uTItuo9eETXFqnz8c63YpGHeVhXkSbiw=";
  };

  nativeBuildInputs = [
    pkg-config
    dbus
    meson
    ninja
  ];
}