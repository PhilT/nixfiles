{ config, lib, pkgs, ... }:
{
  xdg.mime.defaultApplications = {
    "text/plain" = "kitty nvim";
    "text/markdown" = "kitty nvim";
  };
}
