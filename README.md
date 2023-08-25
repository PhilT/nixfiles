# My NixOS Setup

# LUKS full drive encryption

## Bootstrapping a new machine

* Copy this repo to a USB stick
* Create another USB stick with the minimal NixOS ISO from https://nixos.org/download
* Boot up NixOS ISO then run the following commands:

```
sudo -s
mkdir /usb
mount /dev/disk/by-label/NIXFILES /usb
cd /usb
./wifi.sh
ping google.com # To check Wifi connected correctly
./bootstrap.sh -pf <disk> $(mkpasswd)     # Partition and format the drives
```

For later
```
nmcli --ask dev wifi connect <NameofWifi> # Connect to Wifi network
nmcli dev wifi list                       # List Wifi networks
```

## TODO
[ ] Clone repo on target drive


## References
* https://www.gnu.org/software/parted/manual/parted.html
* https://qfpl.io/posts/installing-nixos/
* https://nixos.org/manual/nixos/stable/
