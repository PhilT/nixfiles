{ lib
, python311
, python3Packages
, fetchFromGitHub
, daemon
, pkgs
}:

python3Packages.buildPythonPackage rec {
  pname = "steamvr_utils";
  version = "1.1.3-7"; # This is currently master but hopefully it'll be tagged at some point
  format = "pyproject";

  #src = fetchFromGitHub {
  #  owner = "DavidRisch";
  #  repo = "steamvr_utils";
  #  rev = "master";
  #  sha256 = "1HQiO8JlY170WeWkD8dUwoh6OaH1SL7Gff07SvrrYew=";
  #};
  src = pkgs.nix-gitignore.gitignoreSource [ ] /data/code/steamvr_utils;

  nativeBuildInputs = with python3Packages; [
    setuptools
    wrapPython
  ];

  env.SETUPTOOLS_SCM_PRETEND_VERSION = version;

  propagatedBuildInputs = with python3Packages; [
    (pkgs.callPackage ../steamvr_utils/bluepy.nix {}) # Needed to be able to override the bluepy-helper location to use setcap wrapper version
    psutil
    pyyaml
  ];

#  preBuild = ''
#      cat > pyproject.toml << EOF
#      EOF
#  '';

  postFixup = ''
    wrapProgram "$out/bin/steamvr_utils" \
      --prefix PYTHONPATH : "$PYTHONPATH" \
      --prefix PYTHONPATH : "$out/${python311.sitePackages}" \
      --prefix PATH : "${python311}/bin"
  '';
}