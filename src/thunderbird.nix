{ config, ... }:
{
  programs.thunderbird.enable = true;

  environment.etc = {
    "config/thunderbird/profiles.ini" = {
      mode = "444";
      text = ''
        [Profile0]
        Name=default
        IsRelative=0
        Path=/data/thunderbird_profile
        Default=1

        [General]
        StartWithLastProfile=1
        Version=2
      '';
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.userHome}/.thunderbird - ${config.username} users -"
    "L+ ${config.userHome}/.thunderbird/profiles.ini - - - - /etc/config/thunderbird/profiles.ini"
  ];
}