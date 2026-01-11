# My NixOS Setup

This project uses the system Ruby. When upgrading, once Ruby is installed, do:
```
rm -rf ~/.local/share/gem/ruby/3.4.0
bundle install
```

## Nixx

New commandline tool to build NixOS. type `nixx` to see a list of commands
(you might need to do `lib/nixx` if you're not using the my configuration).

## Initializing a new machine

WARNING: Ensure partitioning is setup in `config/machines.yml`

### Ensure GitHub/GitLab have the SSH keys on your account
```
nixx credentials edit # Create/edit credentials file. Add some blank entries then do:
nixx keys             # Generate and set any missing SSH keys in credentials file
nixx credentials show # Show the contents of the credentials file
```
Upload to GitHub/GitLab etc.

### Build the install ISO with
```
nixx iso
```
### Test in a VM
```
bin/vm <sapling|seedling> install [-f] # Mount install CDROM, enable display
                                       # -f will delete the existing disk image
bin/vm <sapling|seedling> display      # Enable display
bin/vm <sapling|seedling>              # Rely on VFIO display (Nvidia)
```

### Create a USB stick with NixOS ISO (in `result/iso/`)

This will wipe the USB stick and copy the ISO with 2 partitions.
```
nixx usb <dev> # e.g. nixx usb sda
```

### Boot up NixOS ISO, then run the following command to install NixOS and reboot:
```
nixx setup -m <machine_name>  # e.g. nixx setup spruce # to start the installer for spruce
```

After you've logged in, run:
```
cd /data/code/nixfiles
lib/nixx build -s            # Rebuild NixOS and switch to the new machine config
```

And then (if you're on a VM with VFIO):
```
shutdown now          # Shutdown the VM
bin/vm seedling       # Run on the host to start with VFIO on separate display
```
or:
```
reboot                # Reboot, if you're on a physical machine
```

## Wallpaper
```
bin/wallpaper download [left|right] [--apply]
```

## Syncing to public repository

```
bin/sync-to-public
```

Syncs this private repository to the public version, filtering out sensitive files like credentials and machine configurations.

## SSH

SSH keys are used to authenticate between clients and the server.

Naming is `id_<enctype>_<machine>_<service>`
where:
* enctype is the encryption type e.g. ed25519 or ecdsa
* machine is the name of the device e.g. spruce or aramid (See below Naming of devices)
* service e.g. github, gitlab, hetzner, home - In the case the of home this is removed
  from the key name when applied to the machine

Minoo needs an ECDSA key in addition to it's ED25519 key as ED25519 isn't
supported by the SSH Server on Suuno.


## Naming of devices
* Spruce - As the case was originally made of wood (14900K, RTX4090 PC) [ACTIVE]
* Aramid - Strong synthetic fibres (X1 Carbon Gen 12) [ACTIVE]
* Minoo - Some combination of Mini and N100 (File server) [ACTIVE]
* Suuno - A play on the previous phone name (Samsung A15) [ACTIVE]
* Miller - Hetzner server. Hetzner -> Hetzel -> Hermann -> Herman Miller -> Miller [ACTIVE]
* Sapling - Windows 11 Guest VM running on Spruce [RETIRED]
* Seedling - NixOS Guest VM running on Spruce [RETIRED]
* Darko - From Donnie Darko (Razer Blade 2019) [RETIRED]
* Mev - Mobile Electric Visions (Huawei P30 Pro) [RETIRED]
* Sirius - Brightest star in the galaxy (Starlabs Starlite V) [RETIRED]
* Soono - From Something of Nothing (Nothing Phone) [RETIRED]

## References
* https://www.gnu.org/software/parted/manual/parted.html
* https://qfpl.io/posts/installing-nixos/
* https://nixos.org/manual/nixos/stable/
* https://discourse.nixos.org/t/tips-tricks-for-nixos-desktop/28488
* https://nixos.wiki/wiki/Backlight

## Troubleshooting/Issues

Currently not using display scaling due to Renoise (and a few other apps) not
supporting Wayland (blurry fonts).

### SSH

`GIT_SSH_COMMAND="ssh -vvv" git clone example`