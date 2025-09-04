{ config, pkgs, ... }: {
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

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "tb" ''
      notify-send "Syncing Thunderbird profile from server"
      rsync -a --delete phil@minoo:/data/home/thunderbird/ ${config.persistedMachineDir}/thunderbird/
      swaymsg "workspace 8; exec ${config.programs.thunderbird.package}/bin/thunderbird"
      notify-send "Syncing Thunderbird profile to server"
      rsync -a --delete ${config.persistedMachineDir}/thunderbird/ phil@minoo:/data/home/thunderbird/
      notify-send "Finished Syncing Thunderbird profile to server"
    '')
  ];
}