# Standalone NixOS configuration for bootstrapping NixOS from an ISO
{ config, pkgs, ... }: {
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
    <nixos-hardware/lenovo/thinkpad/x1/12th-gen>
    src/base.nix
    src/options.nix
    src/ssh.nix
  ];

  username = "nixos";
  ssh.preventRootLogin = false; # Root access needed when installing in case there are display issues

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "nixi" ''
      ${builtins.readFile ./lib/commands.sh}
      ${builtins.readFile ./lib/disks.sh}
      ${builtins.readFile ./lib/keepass.sh}
      ${builtins.readFile ./lib/run.sh}
      ${builtins.readFile ./lib/steps.sh}
      ${builtins.readFile ./config/aramid.sh}
      ${builtins.readFile ./config/minoo.sh}
      ${builtins.readFile ./config/seedling.sh}
      ${builtins.readFile ./config/spruce.sh}

      run "$@"
    '')

    (writeShellScriptBin "seedling" ''nixi "$@" seedling'')
    (writeShellScriptBin "aramid" ''nixi "$@" aramid'')
    (writeShellScriptBin "spruce" ''nixi "$@" spruce'')
    (writeShellScriptBin "minoo" ''nixi "$@" minoo'')
  ];

  environment.etc."HomeDatabase.kdbx".source = /data/sync/HomeDatabase.kdbx;
}