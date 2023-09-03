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
./rebuild -s Initial
```

## Directory structure

```
USB/
  secrets/
    bashrc.local
    common.env
    machine/
      ssh/
      device                # SSD
      syncthing.cert.pem
      syncthing.key.pem
  dotfiles/   # dotfiles imported by Nix
  neovim/     # Lua and vim file imported by Nix
  src/
    *.nix     # Nix source configuration files
  bootstrap   # Build script for clean machine
  initialize  # Setup a few things after initial install is complete, private keys etc
  rebuild     # Build script for NixOS machine
  *.sh        # additional build scripts used by bootstrap and rebuild
```


## TODO

[x] Make ./bootstrap use the generated configuration for the first install
[x] Get rid of minimal_template and see if I can load vars through machine specific config
[x] Move all env config secrets to secrets/ (e.g. common/, darko/, spruce/, plus any I missed)
[ ] Neomutt (Email client)
    [x] Basic functionality working
    [ ] View HTML email (better formatting needed)
    [ ] How to switch to sidebar?
    [ ] Clickable links
    [ ] View images?
[x] Dark theme - Just Chromium for now
    * Look into i3 DM (https://www.reddit.com/r/unixporn/comments/fltmar/i3gaps_nixos_arch_my_incredible_nixos_desktop/?rdt=57618)
[ ] Check out keepmenu config (change editor?)
[x] Volume controls
[ ] Remove Label stuff for now
[ ] Fix problem with USBs only mounting when loading PCManFM

### Prepare desktop config (for development)
[x] Bash
[x] keymaps for backlight
[x] Neovim
[x] Dotfiles
[x] Dotnet / fsautocomplete package
[x] Syncthing
[x] Keepass
[ ] Docker
[ ] Screenshot ( setup in dwm: `gimp -b '(plug-in-screenshot 0 FALSE 0 0 0 0 0)'` )
[ ] invoice script
[x] Copy `.bashrc_local` to USB. Can be copied as part of bootstrap process
[ ] Ruby https://nixos.org/manual/nixpkgs/stable/#sec-language-ruby

### Game development
[ ] Setup Vulkcan SDK
[x] nVidia drivers
[ ] Release a NixOS package for vim-fsharp
[ ] Test Metter

### Games
[ ] VR drivers
[ ] Vulkcan
[ ] Wine
[ ] Steam
[ ] Lutris

## References
* https://www.gnu.org/software/parted/manual/parted.html
* https://qfpl.io/posts/installing-nixos/
* https://nixos.org/manual/nixos/stable/
* https://discourse.nixos.org/t/tips-tricks-for-nixos-desktop/28488
* https://nixos.wiki/wiki/Backlight
