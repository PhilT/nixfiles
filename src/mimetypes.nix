{ config, lib, pkgs, ... }:
let
  kittyNvim = pkgs.makeDesktopItem {
    name = "kitty-nvim";
    desktopName = "Neovim";
    exec = "kitty nvim %F";
    type = "Application";
    mimeTypes = [ "text/plain" "text/markdown" ];
  };
in {
  environment.systemPackages = [ kittyNvim ];

  xdg.mime.defaultApplications = {
    "text/plain" = "kitty-nvim.desktop";
    "text/markdown" = "kitty-nvim.desktop";
    "x-scheme-handler/http" = "chromium-browser.desktop";
    "x-scheme-handler/https" = "chromium-browser.desktop";
    "text/html" = "chromium-browser.desktop";
  };
}
