# https://astrid.tech/2022/09/22/0/nixos-gpu-vfio/

{ config, lib, pkgs, ... }: {
  environment.etc."qemu/bridge.conf".text = "allow br0\n";
  environment.etc."looking-glass-client.ini".text = ''
    [win]
    fullScreen=yes

    [spice]
    enable=no

    [app]
    capture=nvfbc
  '';
  environment.sessionVariables.OVMF_DIR = "${pkgs.OVMF.fd}/FV";
  environment.systemPackages = with pkgs;[
    (OVMF.overrideAttrs (oldAttrs: { secureBoot = true; msVarsTemplate = true; }))
    qemu
    swtpm
    libhugetlbfs              # Hugepages
    looking-glass-client      # View the VM without the monitors being attached

    (writeShellScriptBin "qemu-system-x86_64-uefi" ''
      qemu-system-x86_64 \
        -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
        "$@"
    '')
  ];

  # FIXME: Or remove: Calling qemu as root anyway so this is probably not needed
  users.groups.vfio = {};
  users.users."${config.username}".extraGroups = [ "vfio" "kvm" ];
  networking = {
    # Disable DHCP on physical interface as it's done on the bridge instead
    useDHCP = false;
    defaultGateway = "192.168.1.1";
    nameservers = [ "192.168.1.1" "8.8.8.8" ];
    bridges."br0".interfaces = [ "eth0" ];

    interfaces."br0".ipv4.addresses = [{
      address = "192.168.1.226";
      prefixLength = 24;
    }];
  };
}