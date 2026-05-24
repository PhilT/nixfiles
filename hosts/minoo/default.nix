# Copy of Sirius config, tweaked to work with the Lenovo X1 Carbon.

{ config, lib, pkgs, ... }: {
  imports = [
    ../../modules/catppuccin.nix

    ./minimal.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/common.nix

    # Sync
    # Not only does this provide a sync command to my phone but also
    # makes the unison command available for other machines to use.
    ../../modules/unison/suuno.nix
    ../../modules/ssh.nix

    # Media Server/Player
    ./kodi_module.nix
    ./kodi.nix

    # Desktop
    ../../modules/desktop/default.nix
    ../../modules/desktop/light.nix

    # Running webservers
    ../../modules/devbox.nix

    # UPS monitoring
    ../../modules/ups.nix
  ];

  # How do we supply the key?
  # Need to change to keyfile instead of prompt?
  # Maybe not though, if permanently on and connected to the TV that
  # might enough to keep simple password login.
  # FIXME: Would be handy if I need to reboot it though to supply the password file
  # via SSH.

  hardware.graphics.enable = true; # TODO: Move into generic config

  # Unison watch on /data exceeds the default inotify ceiling.
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 512;
  };
}