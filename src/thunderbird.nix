{ config, pkgs, ... }: {
  programs.thunderbird.enable = true;

  # Thunderbird normally lives in ~/.thunderbird with a profiles.ini
  # which indicates where the profile is stored. We point this to
  # /data/home/thunderbird so it can be synced between machines.
  # homeDir is ~/
  # persistedHomeDir is /data/home/

  environment.etc."thunderbird/profiles.ini".text = ''
    [Profile0]
    Name=default
    IsRelative=0
    Path=${config.persistedHomeDir}/thunderbird
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
    # app-sync script is in chromium.nix
    (writeShellScriptBin "tb" ''
      app-sync thunderbird thunderbird 7 $@
    '')
  ];
}