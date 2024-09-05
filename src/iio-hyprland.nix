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
    sha256 = "sha256-9tB29tP3ZQ2tU2c+FrWrGqSm70ZrJP8H9WZKzHx55zI=";
  };

  nativeBuildInputs = [
    pkg-config
    dbus
    meson
    ninja
  ];
}