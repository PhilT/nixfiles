{ config, pkgs, ... }: {
  networking.hostId = "d549b408";
  machine = "aramid";
  username = "phil";
  fullname = "Phil Thompson";
  nixfs.enable = true;
}