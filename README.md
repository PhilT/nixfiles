# My NixOS Setup

## Bootstrapping a new machine

* Copy this repo to a USB stick
* Create another USB stick with the minimal NixOS ISO
* Boot up NixOS ISO then do:

```
sudo -s
mkdir /usb
mount /dev/disk/by-label/NIXFILES /usb
cd /usb/nixfiles
./wifi.sh
ping google.com
./bootstrap.sh -dpf <disk> $(mkpasswd)

nmcli --ask dev wifi connect <NameofWifi> # Connect to Wifi network
nmcli dev wifi list                       # List Wifi networks
```

# LUKS Encrypted file system
# Clone repo on target drive

