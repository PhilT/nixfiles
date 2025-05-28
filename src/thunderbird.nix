{ config, ... }: {
  programs.thunderbird.enable = true;

  environment.etc."thunderbird/profiles.ini".text = ''
    [Profile0]
    Name=default
    IsRelative=0
    Path=${config.persistedMachineDir}/thunderbird
    Default=1

    [General]
    StartWithLastProfile=1
    Version=2
  '';

  systemd.tmpfiles.rules = [
    "d ${config.homeDir}/.thunderbird - ${config.username} users -"
    "L+ ${config.homeDir}/.thunderbird/profiles.ini - - - - /etc/thunderbird/profiles.ini"
  ];
}