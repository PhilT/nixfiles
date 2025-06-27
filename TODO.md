# Seedling
[ ] Asks for SSH key twice
[ ] Fails to find id_ed25519_spruce_hetzner.pub (This is probably just old install of KeePass database)
[ ] /data/code/nixfiles owned by root. Probably incorrect. Also SSH key unknown and permission denied
    when trying to git pull. Needs fixing. Need to be able to pull any changes in case of problems

[ ] Neovim wrapper for opening files is broken in Thunar - Unable to find terminal
[ ] I'd still like to have a default Firefox setup that starts off with a blank profile which is then created
    by NixOS
[ ] Does Firefox profile get saved/changed in the correct place?
[ ] Is mode 444 needed anymore if we wipe /etc on boot anyway
[ ] Change kitty image opener to gimp (preview is embedded so that should work nicely)
    Can't do this until Gimp 3 is released
[ ] Video capture
[ ] Learn ranger
[ ] Look into using gvfs-trash to delete files (to a recycle bin)
    I think this is working - although maybe not when using rm
[ ] Configure Matrix
[ ] Research a contact management store that can be accessed with dmenu or the himalaya vim plugin
[ ] Add autocmds to switch colorscheme when viewing emails (himalaya)
[ ] Setup HTML bookmarks to load from dmenu (and open a tab in firefox) - Alternatively add them to the blog
[ ] Investigate journalctl -b warnings
[ ] Add /data{/code,/music,/pictures,/sync,/txt} to places in thunar, this is in ~/.gtk-bookmarks,
[ ] ^ Also add to ranger (if applicable)