{ config, lib, pkgs, ... }:
let
  kittyNvim = pkgs.makeDesktopItem {
    name = "kitty-nvim";
    desktopName = "Neovim";
    exec = "kitty nvim %F";
    type = "Application";
    mimeTypes = [ "text/plain" "text/markdown" ];
  };

  chromiumTab = pkgs.makeDesktopItem {
    name = "chromium-tab";
    desktopName = "Chromium";
    exec = "chromium --new-tab %U";
    type = "Application";
    mimeTypes = [ "x-scheme-handler/http" "x-scheme-handler/https" "text/html" ];
  };
in {
  environment.systemPackages = [ kittyNvim chromiumTab ];

  xdg.mime.defaultApplications = {
    "text/plain" = "kitty-nvim.desktop";
    "text/markdown" = "kitty-nvim.desktop";
    "x-scheme-handler/http" = "chromium-tab.desktop";
    "x-scheme-handler/https" = "chromium-tab.desktop";
    "text/html" = "chromium-tab.desktop";
  };
}
