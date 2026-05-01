{ ... }: {
  system.activationScripts.nutPassword = ''
    if [ ! -f /data/machine/nut-password ]; then
      mkdir -p /data/machine
      tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 32 > /data/machine/nut-password
      chmod 640 /data/machine/nut-password
      chown root:nut /data/machine/nut-password
    fi
  '';

  power.ups = {
    enable = true;
    mode = "standalone";

    ups.cyberpower = {
      description = "CyberPower BR700ELCD-UK";
      driver = "usbhid-ups";
      port = "auto";
    };

    users.upsmon = {
      passwordFile = "/data/machine/nut-password";
      upsmon = "primary";
    };

    upsmon.monitor.cyberpower = {
      system = "cyberpower@localhost";
      powerValue = 1;
      user = "upsmon";
      passwordFile = "/data/machine/nut-password";
      type = "primary";
    };
  };
}
