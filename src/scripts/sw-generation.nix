{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "sw-generation" ''
      if [ -z "$1" ]; then
        echo "$0 <generation>"
        exit 1
      fi
      sudo nix-env --switch-generation $1 -p /nix/var/nix/profiles/system
      sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
    '')
  ];
}
