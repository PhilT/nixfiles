{ lib
, python3Packages
, fetchPypi
, pkg-config
, glib
, nix-gitignore
}:

python3Packages.buildPythonPackage rec {
  pname = "bluepy";
  version = "1.3.0";
  format = "setuptools";

  src = nix-gitignore.gitignoreSource [ ] /data/code/bluepy;

  buildInputs = [ glib ];
  nativeBuildInputs = [ pkg-config ];

  # tests try to access hardware
  checkPhase = ''
    $out/bin/blescan --help > /dev/null
    $out/bin/sensortag --help > /dev/null
    $out/bin/thingy52 --help > /dev/null
  '';
  pythonImportsCheck = [ "bluepy" ];

  meta = with lib; {
    description = "Python interface to Bluetooth LE on Linux";
    homepage = "https://github.com/IanHarvey/bluepy";
    maintainers = with maintainers; [ georgewhewell ];
    platforms = platforms.linux;
    license = licenses.gpl2;
  };
}