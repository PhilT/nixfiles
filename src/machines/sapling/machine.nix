{ config, pkgs, ... }: {
  machine = "sapling";
  username = "phil";
  fullname = "Phil Thompson";
  luks.enable = false;
}