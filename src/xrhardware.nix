{ lib
, stdenv
, fetchgit
, bash
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "xrhardware-udev-rules";
  version = "0.0.1";

  src = fetchgit {
    url = "https://gitlab.freedesktop.org/monado/utilities/xr-hardware";
    rev = "38624e02fdeddd212b56eb6e816a7089424fd5de";
    sha256 = "b6IbvFPsROS2vj1yXMSk2+KImy9iCA07xsIuGxWU/bM=";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    mkdir -p $out/lib/udev/rules.d
    cp 70-xrhardware* $out/lib/udev/rules.d/
  '';

  meta = with lib; {
    description = "Udev rules to make supported XR devices available with user-grade permissions";
    homepage = "https://gitlab.freedesktop.org/monado/utilities/xr-hardware";
    license = licenses.boost;
    longDescription = ''
      These udev rules are intended to be used as a package under 'services.udev.packages'.
      They will not be activated if installed as 'environment.systemPackages' or 'users.user.<user>.packages'.

      Additionally, you may need to enable 'hardware.uinput'.
    '';
    platforms = platforms.linux;
    #maintainers = with maintainers; [ philthompson ];
  };
})
