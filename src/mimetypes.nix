{ config, lib, pkgs, ... }:
{
  xdg.mime.defaultApplications = {
    "text/plain" = "kitty nvim";
    "text/markdown" = "kitty nvim";
    "x-scheme-handler/http" = "chromium-browser.desktop";
    "x-scheme-handler/https" = "chromium-browser.desktop";
    "text/html" = "chromium-browser.desktop";
  };
}
