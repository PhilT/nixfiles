[ ] Fix selected text color in Neomutt (might be alacritty)
[ ] Package dbgate SQL Client (or use the AppImage)
[*] keepmenu still a bit weird on pasting some passwords (e.g. privateemail) - Support issue raised
[ ] Inverse stack dwm on second monitor (main window on the right, stack on the left)
[ ] Fix squashed Telescope view for Grep
[ ] When copying secrets from /usb/nixos-files/secrets to /data/code/nixos-files/secrets
    find /var/www/html -type d -print0 | xargs -0 chmod 755
    find /var/www/html -type f -print0 | xargs -0 chmod 644
[ ] slstatus - Need separate branch for spruce
[ ] FIREFOX: Remove Getting started and import bookmark bookmarks
[ ] Setup dmenu bookmarks
[ ] Investigate journalctl -b warnings:
    [ ] efifb: Ignoring BGRT: unexpected or invalid BMP data
    [ ] nvme nvme0: missing or invalid SUBNQN field
    [ ] usb: port power management may be unreliable
    [ ] kernel: usb 1-8.4.1: current rate 16000 is different from the runtime rate 32000
        kernel: usb 1-8.4.1: current rate 24000 is different from the runtime rate 16000
        kernel: usb 1-8.4.1: 3:3: cannot set freq 24000 to ep 0x82
    [ ] iwlwifi 0000:00:14.3: api flags index 2 larger than supported by driver
    [ ] thermal thermal_zone2: failed to read out thermal zone (-61)
    [ ] warning: logrotate in debug mode does nothing except printing debug messages!  Consider using verbose mode (-v) instead if this is not what you want.
    [ ] dbus-daemon[1307]: dbus[1307]: Unknown username "pulse" in message bus configuration file
    [ ] dbus-daemon[1307]: dbus[1307]: Unknown group "netdev" in message bus configuration file

    [ ] (uetoothd)[1303]: ConfigurationDirectory 'bluetooth' already exists but the mode is different. (File system: 755 ConfigurationDirectoryMode: 555)
    [ ] bluetoothd[1303]: src/main.c:check_options() Unknown key Enable for group General in /etc/bluetooth/main.conf
    [ ] bluetoothd[1303]: profiles/audio/vcp.c:vcp_init() D-Bus experimental not enabled
        bluetoothd[1303]: src/plugin.c:plugin_init() Failed to init vcp plugin
        bluetoothd[1303]: profiles/audio/mcp.c:mcp_init() D-Bus experimental not enabled
        bluetoothd[1303]: src/plugin.c:plugin_init() Failed to init mcp plugin
        bluetoothd[1303]: profiles/audio/bap.c:bap_init() D-Bus experimental not enabled
        bluetoothd[1303]: src/plugin.c:plugin_init() Failed to init bap plugin
    [ ] nfmqh57cb7y6hq6qhkx8m5l2avl6xvj4-merge-syncthing-config[1627]: curl: (7) Failed to connect to 127.0.0.1 port 8384 after 1 ms: Couldn't connect to server
    [ ] nfmqh57cb7y6hq6qhkx8m5l2avl6xvj4-merge-syncthing-config[2632]: parse error: Invalid numeric literal at line 1, column 5
    [ ] ln: failed to create symbolic link '/home/phil/.config/alacritty.yml': Permission denied
    [ ] exFAT-fs (sdb1): Volume was not properly unmounted. Some data may be corrupt. Please run fsck.
    [ ] xhci_hcd 0000:00:14.0: xHC error in resume, USBSTS 0x411, Reinit
    [ ] Error getting 'loop0' information: Failed to get status of the device loop0: No such device or address (g-bd-loop-error-quark, 2)
[ ] Rebuild failures:
    [ ] warning: mdadm: Neither MAILADDR nor PROGRAM has been set. This will cause the `mdmon` service to crash.
[ ] Add /data{/code,/music,/pictures,/sync,/txt} to places in pcmanfm, this is in ~/.gtk-bookmarks,
    Settings are in ~/.config/pcmanfm/default/pcmanfm.conf

[x] Can't view (and click on) HTML email links in Neomutt
[x] Add /data to CDPATH
[x] Screen tearing in Firefox even with vsync on nvidia drivers
[x] Don't fade/reduce opacity of Feh images
[x] How to switch screens (keyboard shortcut) -- WIN+.
[x] How to update NixOS? - sudo nix-channel --update
[x] Setup custom config for fred (Done for now)
[x] Finish configuring syncthing
[-] Setup derivation for FLStudio (Audio a bit wonky, need to test)

[x] Make ./bootstrap use the generated configuration for the first install
[x] Get rid of minimal_template and see if I can load vars through machine specific config
[x] Move all env config secrets to secrets/ (e.g. common/, darko/, spruce/, plus any I missed)
[ ] Neomutt (Email client)
    [x] Basic functionality working
    [x] View HTML email (better formatting needed)
    [x] How to switch to sidebar? (`c` to change mailbox)
    [x] Clickable links - just works
    [ ] View images?
    [ ] Can't see sent messages (and more broadly setting up local folders)
    [ ] Look into warning generated when running surf
[x] Dark theme - Just Chromium for now
[ ] Check out keepmenu config (change editor?)
[x] Volume controls
[x] Whatsapp
[x] Remove Label stuff for now
[x] Fix problem with USBs only mounting when loading PCManFM

### DWM
[x] Wifi icon
[x] Volume icon
[ ] Bluetooth icon
[x] Remove seconds from time

### Prepare desktop config (for development)
[x] Bash
[x] keymaps for backlight
[x] Neovim
[x] Dotfiles
[x] Dotnet / fsautocomplete package
[x] Syncthing
[x] Keepass
[x] Docker
[x] Screenshot (Flameshot)
[x] invoice script
    [ ] Mail company on generation (add mailto option to client config.yml)
[x] Copy `.bashrc_local` to USB. Can be copied as part of bootstrap process
[ ] Ruby https://nixos.org/manual/nixpkgs/stable/#sec-language-ruby

### Game development
[ ] Setup Vulkcan SDK
[x] nVidia drivers
[x] Release a NixOS package for vim-fsharp (Just pulled plugins from Github)
[x] Test Matter

### Games
[?] VR drivers - Installed monado, need to test
[x] Vulkcan - I think this works by default now
[x] Wine
[x] Steam - Need to try steam-run, hopefully it works with Proton GE
[?] Lutris - Needs configuring I think

### Surf
[ ] chromebar
[ ] chromekeys
[ ] clipboard (possibly)
[ ] history
[ ] homepage
[ ] keycodes (possibly to fix zoom in not working)
[ ] modal


