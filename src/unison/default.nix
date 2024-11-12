{ config, pkgs, lib, ... }:
let
  pathsConfig = lib.lists.foldr (path: str: "path = ${path}\n${str}") "";
  folders = map (path: "d ${config.dataDir}/${path} - ${config.username} users -");
in
{
  imports = [ ./options.nix ];
  environment.systemPackages = with pkgs; [ unison ];

  environment.etc."config/unison/common.prf" = {
    mode = "444";
    text = ''
      sshcmd = /run/current-system/sw/bin/ssh
      batch = true
      maxthreads = 30
      fastcheck = true
      times = true

      copyonconflict = true
      prefer = newer
      repeat = watch

      ignore = Name .thumbnails
      ignore = Name .devenv
      ignore = Name *.tmp
      ignore = Name .*~
      ignore = Name *~

      ${pathsConfig config.unison.paths}
      ${config.unison.extraConfig}
    '';
  };

  systemd.services.unison = {
    enable = true;
    description = "Unison filesync";
    serviceConfig = {
      Type = "simple";
      ExecStart = "/run/current-system/sw/bin/sync_${config.unison.target}";
      ExecStop = "/run/current-system/sw/bin/pkill unison";
      Restart = "always";
      RestartSec = "5";
      RestartSteps = "10";
      RestartMaxDelaySec = "1800";
      User = config.username;
      Group = "users";
    };
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
  };

  systemd.tmpfiles.rules = [
    "d ${config.userHome} - ${config.username} users -"
    "d ${config.userHome}/.unison - ${config.username} users -"

    "L+ ${config.userHome}/.unison/common.prf - - - - /etc/config/unison/common.prf"
  ] ++ (folders config.unison.paths);
}