# My NixOS Setup

## Prerequesites
* Ensure nixos code is committed and pushed with clean stage
* Ensure secrets/ are copied to USB

## Bootstrapping a new machine

WARNING: Disk needs to be set in 2 places at the moment: secrets/machine/device
and src/machine/minimal.nix. Need to set minimal.nix to pull from device


* Copy this repo to a USB stick
    ```
    rsync -r --exclude=result . /run/media/phil/nixos-files/nixos-files
    umount /run/media/phil/nixos-files
    ```
* Add the ssh key to GitHub
* Create another USB stick with the latest **Minimal NixOS** ISO from https://nixos.org/download/#nixos-iso
    ```
    lsblk --list | grep sda[1-9]
    sudo umount /dev/sda1
    sudo umount /dev/sda2 # If listed in above command
    sudo dd if=nixos.iso of=/dev/sda bs=1M status=progress
    ```

* Boot up NixOS ISO then run the following commands:
```
sudo -s
mkdir /usb
mount /dev/disk/by-label/nixos-files /usb
cd /usb/nixos-files
./bootstrap -pf <darko|spruce>     # Partition and format the drives
reboot # And remove USB sticks
```

After first boot, run:
```
sudo mkdir /usb
sudo mount /dev/disk/by-label/nixos-files /usb
cd /usb/nixos-files
./initialize
./build -s
```

After booting, try adding all Bluetooth devices with:
```
./bluetooth
```

## Directory structure

```
USB/
  secrets/
    bashrc.local
    common.env
    <machine>/
      ssh/
      device                # SSD
      syncthing.cert.pem
      syncthing.key.pem
  dotfiles/   # dotfiles imported/linked by Nix
  neovim/     # Lua and vim file imported by Nix
  src/
    *.nix     # Nix source configuration files
  bootstrap   # Build script for clean machine
  initialize  # Setup a few things after initial install is complete, private keys etc
  build     # Build script for NixOS machine
  *.sh        # additional build scripts used by bootstrap and build
```

## Naming of devices
* Spruce - As it was mainly made of wood (originally)
* Darko - Just like the name, from Donnie Darko
* Mev - Mobile Electric Visions
* Sirius - Brightest star in the galaxy (referring to Starlabs)
* Soono - From Something of Nothing (Nothing Phone)
* Suuno - A play on the previous phone name (Samsung A15)
* Aramid - Strong synthetic fibres (X1 Carbon)

## References
* https://www.gnu.org/software/parted/manual/parted.html
* https://qfpl.io/posts/installing-nixos/
* https://nixos.org/manual/nixos/stable/
* https://discourse.nixos.org/t/tips-tricks-for-nixos-desktop/28488
* https://nixos.wiki/wiki/Backlight