{ config, pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      (ruby_3_3.withPackages (ps: with ps; [ solargraph ]))
    ];

    etc = {
      "config/irbrc" = {
        mode = "444";
        text = ''
          Reline::Face.config(:completion_dialog) do |conf|
            conf.define :default, foreground: :white, background: :gray
            conf.define :enhanced, foreground: :bright_white, background: :magenta
            conf.define :scrollbar, foreground: :white, background: :blue
          end
        '';
      };
    };
  };

  systemd.tmpfiles.rules = [
    "L+ /home/phil/.irbrc - - - - /etc/config/irbrc"
  ];
}