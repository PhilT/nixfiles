{ config, pkgs, ... }:

{
  programs.bash.interactiveShellInit = ''
    source ${../dotfiles/himalaya_completion}
  '';

  environment = {
    systemPackages = with pkgs; [
      himalaya

      (writeShellScriptBin "m-empty" ''
        echo "Getting size of Trash folder..."
        emails=$(himalaya list -f Trash -s 10000 | sed '2 d')
        ids=$(echo "$emails" | sed -E 's/([0-9]+).*/\1/')
        echo "Deleting..."
        for i in $ids; do
          himalaya delete -f Trash $i > /dev/null
        done
        echo "Done."
      '')

      # Select the ID in the first column of each subsequent line
      # then concatenate it into a space separated list.
      (writeShellScriptBin "m-ids" ''
        sed -E 's/([0-9]+) .*$/\1/' | sed ':a; N; $!ba; s/\n/ /g'
      '')

      (writeShellScriptBin "m-subject-with" ''
        if [ -z "$1" ]; then
          echo "Returns IDs contain <text> in the subject"
          echo "Usage:"
          echo "  $0 text"
          exit 1
        fi

        himalaya search SUBJECT $1 | m-ids
      '')

      # list email
      (writeShellScriptBin "m-list" ''
        himalaya list -w 1080 | sed -E 's/│/ /g'
      '')

      # e.g. mail-subject-with sometext | $0
      (writeShellScriptBin "m-del" ''
        m-list | dmenu -l 30 -p "Delete:" | m-ids | xargs himalaya delete
      '')

      (writeShellScriptBin "m-arch" ''
        m-list | dmenu -l 30 -p "Archive:" | m-ids | xargs himalaya move Archive
      '')

      (writeShellScriptBin "m-read" ''
        m-list | dmenu -l 30 -p "Open:" | m-ids | xargs himalaya read
      '')

      (writeShellScriptBin "m-spam" ''
        m-list | dmenu -l 30 -p "Move to spam folder:" | m-ids | xargs himalaya move Spam
      '')
    ];

    etc = {
      "himalaya.toml".source = ../dotfiles/himalaya.toml;
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.xorg.xdgConfigHome}/himalaya - phil users"
    "L+ ${config.xorg.xdgConfigHome}/himalaya/config.toml - - - - /etc/himalaya.toml"
  ];
}