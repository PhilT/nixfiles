{ config, lib, pkgs, fetchurl, ... }: {
  environment = {
    systemPackages = with pkgs; [
      (appimageTools.wrapType2 {
        pname = "dbgate";
        version = "5.2.6";
        src = pkgs.fetchurl {
          url = "https://github.com/dbgate/dbgate/releases/download/v5.2.6/dbgate-5.2.6-linux_x86_64.AppImage";
          sha256 = "Bw5+MaYXuOT1D5z3cImToS6Add/tDwy9r/b7MsviyUE=";
        };
      })
    ];

    etc."config/dbgate/settings.json" = {
      mode = "444";
      text = (builtins.toJSON {
        "app.useNativeMenu" = true;
        currentTheme = "theme-dark";
      });
    };
  };

  systemd.tmpfiles.rules = [
    "C+ ${config.userHome}/.dbgate - ${config.username} users - /etc/config/dbgate"
  ];
}