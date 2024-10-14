{ config, lib, pkgs, ... }:
{
  imports = [
    ./environment.nix
    ./audio.nix
    ./fonts.nix
    ./mimetypes.nix

    ./dbgate.nix
    ./filemanager.nix
    ./firefox.nix
    ./git.nix
    ./keepmenu.nix
    ./kitty.nix
    ./neovim.nix
    ./programs.nix
    ./qemu.nix
    ./qutebrowser.nix
    ./thunderbird.nix
    ./tmux.nix
  ];
}