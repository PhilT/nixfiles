# To pair a device on both Linux and Windows:
# 1. Add the user as owner in Permissions in: HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\BTHPORT\Parameters\Keys
# 2. Subkeys should appear after a refresh in Regedit
# 3. Export this key
# On Linux:
# 4. sudo su
# 5. cd /lib/bluetooth/<your bluetooth controller>/<your device>
#     e.g. my Shokz headphones are C0:86:B3:80:58:9A
# 6. nvim info
# 7. Change [LinkKey] -> Key to the hex value specified in the regkey
# 8. systemd restart bluetooth
{ config, pkgs, ... }: {
  hardware.bluetooth.enable = true;
  hardware.bluetooth.settings = {
    General = {
      Enable = "Source,Sink,Media,Socket";
      AutoEnable = true;
    };
  };
}