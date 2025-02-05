# https://astrid.tech/2022/09/22/0/nixos-gpu-vfio/


{ config, lib, pkgs, ... }:
{
  virtualisation.spiceUSBRedirection.enable = true;
  environment.systemPackages = with pkgs;[
    samba
    (qemu.overrideAttrs (oldAttrs: { secureBoot = true; msVarsTemplate = true; }))
    swtpm
    cpuset

    (writeShellScriptBin "qemu-system-x86_64-uefi" ''
      qemu-system-x86_64 \
        -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
        "$@"
    '')
  ];

  # FIXME: Or remove: Calling qemu as root anyway so this is probably not needed
  users.groups.vfio = {};
  users.users."${config.username}".extraGroups = [ "vfio" "kvm" ];
}