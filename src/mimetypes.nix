{ config, lib, pkgs, ... }:
{
  xdg.mime.defaultApplications = {
    "text/plain" = "kitty nvim";
    "text/markdown" = "kitty nvim";
    "x-scheme-handler/http" = "firefox-esr.desktop";
    "x-scheme-handler/https" = "firefox-esr.desktop";
    "text/html" = "firefox-esr.desktop";
  };
}
