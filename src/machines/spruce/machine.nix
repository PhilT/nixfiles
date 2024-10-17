{ config, pkgs, ... }: {
  machine = "spruce";
  username = "phil";
  fullname = "Phil Thompson";
  luks.device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_2TB_S6Z2NJ0TA26792J_1-part2";
}