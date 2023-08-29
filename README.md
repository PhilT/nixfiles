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
./initialize
./rebuild -r
```

## Directory structure

```
USB/
  common/
    .bash.private
    common.env
  machine/
    .ssh/
    machine_name.env
    syncthing.cert.pem
    syncthing.key.pem
  src/
    dotfiles/   # dotfiles imported by Nix
    neovim/     # Lua and vim file imported by Nix
    *.nix # Nix source configuration
    minimal_template.nix # outputs to minimal.nix with vars interpolated from .env files
  bootstrap   # Build script for clean machine
  initialize  # Setup a few things after initial install is complete, private keys etc
  rebuild     # Build script for NixOS machine
  *.sh        # additional build scripts used by bootstrap and rebuild
```


## TODO

### Prepare desktop config (for development)
[x] Bash
[x] keymaps for backlight
[x] Neovim
[x] Dotfiles
[x] Dotnet / fsautocomplete package
[ ] Syncthing
[ ] Release a NixOS package for vim-fsharp
[ ] Docker
[ ] invoice script
[ ] Copy `.bashrc_local` to USB. Can be copied as part of bootstrap process
[ ] Sync/ Syncthing
[ ] Ruby https://nixos.org/manual/nixpkgs/stable/#sec-language-ruby

### Game development
[ ] Setup Vulkcan SDK
[ ] nVidia drivers

### Games
[ ] Proton
[ ] Steam
[ ] VR drivers

## References
* https://www.gnu.org/software/parted/manual/parted.html
* https://qfpl.io/posts/installing-nixos/
* https://nixos.org/manual/nixos/stable/
* https://discourse.nixos.org/t/tips-tricks-for-nixos-desktop/28488
* https://nixos.wiki/wiki/Backlight
