{ config, lib, pkgs, ... }:
{
  virtualisation.spiceUSBRedirection.enable = true;
  environment = with pkgs; {
    systemPackages = [
      samba
      qemu

      (writeShellScriptBin "qemu-system-x86_64-uefi" ''
        qemu-system-x86_64 \
          -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
          "$@"
      '')

    ];
  };
}