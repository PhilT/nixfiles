[ ] Change kitty image opener to gimp (preview is embedded so that should work nicely)
[ ] Video capture
[ ] Learn ranger
[ ] Look into using gvfs-trash to delete files (to a recycle bin)
[ ] Configure Matrix
[ ] Research a contact management store that can be accessed with dmenu or the himalaya vim plugin
[ ] Add autocmds to switch colorscheme when viewing emails (himalaya)
[ ] Setup HTML bookmarks to load from dmenu (and open a tab in firefox) - Alternatively add them to the blog
[ ] Investigate journalctl -b warnings
[ ] Add /data{/code,/music,/pictures,/sync,/txt} to places in pcmanfm, this is in ~/.gtk-bookmarks,
    Settings are in ~/.config/pcmanfm/default/pcmanfm.conf
[ ] ^ Also add to ranger (if applicable)

[x] FIREFOX: Remove Getting started and import bookmark bookmarks
[x] Look into storing and retrieving layout that would persist across logins so it might be possible to build some persistent layout that can be used in the long term.
    [ ] Added patches but doesn't seem to be working correctly. Might try a proper reboot and test with fresh eyes. Nope. Still not working
[x] Bluetooth icon (possibly with clickable startup of wifi connections in dmenu) - or maybe just a bt shortcut (e.g. bt mifo, bt sony to connect (I think sony connect automatically))
[x] Add column layout to DWM
[x] Inverse stack dwm on second monitor (main window on the right, stack on the left and add columns) (The patch is actually called rmaster)
    * This doesn't seem to work with column layout but that might be okay. rmaster might be enough on the standard tile view
[x] Customise cmus, (play/pause key binding), status bar view, etc, start from shortcut - WIN+CTRL+SPACE,p,k,h,l
[x] Add named tags in DWM - Reason: Can separate tags into work, game, nixos, blog. Ended up with icons. We'll see.
[x] Add shortcut for Slack
[x] Fix Himalaya - Switch off sync
[x] Fix flameshot not loading on startup
[x] slstatus - Need separate branch for spruce
[x] Fix squashed Telescope view for Grep
[x] Related to himalaya-vim, add a secondary (and a light one) colorscheme to Neovim
[x] Look into himalaya-vim
[x] Package dbgate SQL Client (or use the AppImage)
[x] Rebuild failures:
    [x] warning: mdadm: Neither MAILADDR nor PROGRAM has been set. This will cause the `mdmon` service to crash. - Fixed with channel update
[x] When copying secrets from /usb/nixos-files/secrets to /data/code/nixos-files/secrets
    find /var/www/html -type d -print0 | xargs -0 chmod 755
    find /var/www/html -type f -print0 | xargs -0 chmod 644
[x] keepmenu still a bit weird on pasting some passwords (e.g. privateemail) - Support issue raised
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
    [x] How to switch to sidebar? (`c` to change mailbox or CTRL+j/k and CTRL+o to open)
    [x] Clickable links - just works
    [ ] View images?
    [ ] Can't see sent messages (and more broadly setting up local folders)
    [ ] Look into warning generated when running surf
    [ ] Reverse order of emails not working
    [ ]
[x] Dark theme - Just Chromium for now
[x] Check out keepmenu config (change editor?)
[x] Volume controls
[x] Whatsapp
[x] Remove Label stuff for now
[x] Fix problem with USBs only mounting when loading PCManFM

### DWM
[x] Wifi icon
[x] Volume icon
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