# My NixOS Setup

# LUKS full drive encryption

## Bootstrapping a new machine

* Copy this repo to a USB stick
* Add the ssh key to GitHub
* Create another USB stick with the minimal NixOS ISO from https://nixos.org/download
* Boot up NixOS ISO then run the following commands:
```
sudo -s
mkdir /usb
mount /dev/disk/by-label/NIXFILES /usb
cd /usb
./bootstrap -pf <darko|spruce>     # Partition and format the drives
```

After first boot, run:
```
sudo mkdir /usb
sudo mount /dev/disk/by-label/NIXFILES /usb
cd /usb
./rebuild.sh <darko|spruce> # Subsequent runs can omit the param as the hostname is used
```

## TODO

### Prepare desktop config (for development)
[x] Bash
[ ] Neovim
[ ] Dotfiles
[ ] Docker
[ ] Copy `.bashrc_local` to USB. Can be copied as part of bootstrap process
[ ] Sync/ Syncthing
[ ] Ruby https://nixos.org/manual/nixpkgs/stable/#sec-language-ruby

### Game development
[ ] Setup Vulkcan SDK
[ ] nVidia drivers
[ ] 

### Games
[ ] Proton
[ ] Steam
[ ] VR drivers 



## References
* https://www.gnu.org/software/parted/manual/parted.html
* https://qfpl.io/posts/installing-nixos/
* https://nixos.org/manual/nixos/stable/
* https://discourse.nixos.org/t/tips-tricks-for-nixos-desktop/28488
