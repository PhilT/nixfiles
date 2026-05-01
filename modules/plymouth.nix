# Graphical login for drive encryption
# Logs to /var/log/boot.log

{ config, lib, pkgs, ... }: {
  boot.plymouth = {
    enable = true;
    font = "${pkgs.atkinson-hyperlegible}/share/fonts/opentype/AtkinsonHyperlegible-Regular.otf";
  };

  catppuccin.plymouth.enable = true;
  catppuccin.plymouth.flavor = "mocha";

  # Reduce boot logging to prevent Plymouth falling back to text mode
  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;
  boot.kernelParams = [
    "udev.log_priority=3"
    "rd.systemd.show_status=auto"
  ];
}