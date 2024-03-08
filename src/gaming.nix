# The Steam client will be downloaded or updated at ~/.local/share/Steam by default.
#
# lsusb - to check hardware IDs
#

# To get Joysticks working for some Proton/Wine games follow these steps:
#
# * Find the steamid for the game by name with:
#     grep -i "<name e.g. elite>" /games/steam/steamapps/appmanifest_*.acf
#
# * Import the reg keys:
#     env WINEPREFIX=$STEAM_LIBRARY/compatdata/<steamid>/pfx regedit joysticks/winebus.reg
#     env WINEPREFIX=$STEAM_LIBRARY/compatdata/<steamid>/pfx regedit joysticks/enum_winebus.reg
#

{ config, pkgs, ... }:

let
  steam_dir = "/games/steam";
in
{
  nixpkgs.config.allowUnfree = true;
  programs.steam.enable = true;
  programs.gamemode.enable = true; # Run with: gamemoderun ./game, verify with: gamemoded -s

  security.wrappers.bluepy-helper = {
    owner = "root";
    group = "root";
    capabilities = "cap_net_raw,cap_net_admin+eip";
    source = "${pkgs.python3Packages.bluepy}/${pkgs.python311.sitePackages}/bluepy/bluepy-helper";
  };

  environment = {
    sessionVariables = {
      STEAM_DIR = steam_dir;
      STEAM_LIBRARY = "${steam_dir}/steamapps";
    };

    systemPackages = with pkgs; [
      game-devices-udev-rules # Udev rules to make controllers available with non-sudo permissions
      lutris                  # For non-steam games from other app stores or local, also supports steam games
      jstest-gtk              # For testing Joysticks
    ];
  };

  systemd.tmpfiles.rules = [
    "d /home/phil/log - phil users -"
    "d /home/phil/.local/share/Steam - phil users -"
    "L+ /home/phil/.local/share/Steam/steamapps - - - - /games/steam/steamapps"
  ];
}