# My NixOS Setup

## Bootstrapping a new machine

WARNING: Disk needs to be set in: `src/machines/<machine>/drive`

* Copy this repo and KeePass database to a USB stick
    ```
    ./sync-and-remove
    ```
* Ensure GitHub/GitLab have the SSH keys on your account
* Create another USB stick with the latest **Minimal NixOS** ISO from https://nixos.org/download/#nixos-iso
    If USB previously used as ISO then it will have 2 partitions which should be
    unmounted before runnning `dd`:
    ```
    lsblk --list | grep sda[1-9]
    sudo umount /dev/sda1 /dev/sda2
    sudo dd if=/data/downloads/nixos.iso of=/dev/sda bs=1M status=progress
    sudo umount /dev/sda1 /dev/sda2
    ```

* Boot up NixOS ISO then run the following commands:
```
sudo -s
mkdir /usb
mount /dev/disk/by-label/nixos-data /usb
cd /usb/nixos-files
./bootstrap -pf <aramid|spruce>     # Partitions and formats the drives
reboot                              # and remove USB sticks
```

After first boot, run:
```
sudo mkdir /usb
sudo mount /dev/disk/by-label/nixos-data /usb
cd /usb/nixos-files
./build -s
```

## Directory structure

```
USB/
  secrets/    # Temporary folder for hashed_password, wifi and public ssh keys
  dotfiles/   # dotfiles imported/linked by Nix
  neovim/     # Lua and vim file imported by Nix
  src/*.nix   # Nix source configuration files
  lib/*.sh    # additional build scripts used by bootstrap and build
  bootstrap   # Build script for clean machine
  build       # Build script for NixOS machine (Also connects network and sets up SSH keys)
```

## Naming of devices
* Spruce - As it was mainly made of wood (13900K, RTX4090 Deskop PC)
* Darko - Just like the name, from Donnie Darko (Razer Blade 2019) - Retired
* Mev - Mobile Electric Visions (Huawei P30 Pro) - Retired
* Sirius - Brightest star in the galaxy (Starlabs Starlite V)
* Soono - From Something of Nothing (Nothing Phone)
* Suuno - A play on the previous phone name (Samsung A15)
* Aramid - Strong synthetic fibres (X1 Carbon)
* Minoo - Some combination of Mini and N100 (File server)
* Sapling - NixOS-WSL install on Spruce

## References
* https://www.gnu.org/software/parted/manual/parted.html
* https://qfpl.io/posts/installing-nixos/
* https://nixos.org/manual/nixos/stable/
* https://discourse.nixos.org/t/tips-tricks-for-nixos-desktop/28488
* https://nixos.wiki/wiki/Backlight

## Troubleshooting

### SSH

`GIT_SSH_COMMAND="ssh -vvv" git clone example`

### Bootstrap