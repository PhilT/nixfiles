# My NixOS Setup

## Initializing a new machine

WARNING: Ensure partitioning is setup in `config/<machine>.sh`

* Ensure GitHub/GitLab have the SSH keys on your account
* Build the install ISO with
    ```
    ./mkiso
    ```
* Test in a VM
    ```
    ./vm
    ```
* Or, create a USB stick with NixOS ISO (in `result/iso/`)
    If USB previously used as ISO then it will have 2 partitions which should be
    unmounted before runnning `dd`:
    ```
    lsblk --list | grep sda[1-9]
    sudo umount /dev/sda1 /dev/sda2
    sudo dd if=result/iso/*.iso of=/dev/sda bs=1M status=progress
    sudo umount /dev/sda1 /dev/sda2
      ```
* Boot up NixOS ISO, then run the following commands:
```
<machine> [options] [branch]  # e.g. spruce # to start the installer for spruce
reboot                        # and remove USB sticks
```

After first boot, run:
```
cd /data/nixfiles
./build -s
```

## Naming of devices
* Spruce - As it was mainly made of wood (13900K, RTX4090 Deskop PC) [ACTIVE]
* Darko - Just like the name, from Donnie Darko (Razer Blade 2019) [RETIRED]
* Mev - Mobile Electric Visions (Huawei P30 Pro) [RETIRED]
* Sirius - Brightest star in the galaxy (Starlabs Starlite V) [RETIRED]
* Soono - From Something of Nothing (Nothing Phone) [RETIRED]
* Suuno - A play on the previous phone name (Samsung A15) [ACTIVE]
* Aramid - Strong synthetic fibres (X1 Carbon) [ACTIVE]
* Minoo - Some combination of Mini and N100 (File server) [ACTIVE]
* Sapling - Windows 11 Guest VM running on Spruce [ACTIVE]
* Seedling - NixOS Guest VM running on Spruce [DEVELOPING]

## References
* https://www.gnu.org/software/parted/manual/parted.html
* https://qfpl.io/posts/installing-nixos/
* https://nixos.org/manual/nixos/stable/
* https://discourse.nixos.org/t/tips-tricks-for-nixos-desktop/28488
* https://nixos.wiki/wiki/Backlight

## Troubleshooting

### SSH

`GIT_SSH_COMMAND="ssh -vvv" git clone example`