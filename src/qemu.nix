# https://astrid.tech/2022/09/22/0/nixos-gpu-vfio/

{ config, lib, pkgs, ... }:
let
  vendor = "10de";
  gpu = "2684";
  audio = "22ba";
  gpuIds = "${vendor}:${gpu},${vendor}:${audio}";
in {
  #environment.etc."qemu/bridge.conf".text = "allow br0\n";
  environment.etc."looking-glass-client.ini".text = ''
    [win]
    fullScreen=yes

    [input]
    rawMouse=yes

    [spice]
    audio=no
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

  systemd.extraConfig = ''
    DefaultLimitMEMLOCK=infinity
  '';

  systemd.tmpfiles.rules = [
    "f /dev/shm/looking-glass 0660 phil kvm -"
  ];

  boot.kernelParams = [
    "intel_iommu=on"
    #"iommu=pt" # Might be needed for performance. Test and see
    #"hugepagesz=1G"
    #"hugepages=24"
  ];

  boot.extraModprobeConfig = ''
    options vfio-pci ids=${gpuIds}
  '';

  boot.kernelModules = [ "vfio_pci" "vfio" "vfio_iommu_type1" "kvm-intel" ];

  # These rules only apply to connected devices. E.g. If my wheel is off it won't apply the permissions
  services.udev.extraRules = ''
    SUBSYSTEM=="vfio", TAG+="uaccess"
    SUBSYSTEM=="usb", TAG+="uaccess"
    SUBSYSTEM=="hugetlbfs", ENV{DEVNAME}=="*hugepages", MODE="0770", GROUP="hugepages"
  '';

  users.groups.vfio = {};
  users.groups.hugepages = {};
  users.users."${config.username}".extraGroups = [
    "kvm"
    "vfio"
    "hugepages"
  ];

  #networking = {
  #  # Disable DHCP on physical interface as it's done on the bridge instead
  #  useDHCP = false;
  #  defaultGateway = "192.168.1.1";
  #  nameservers = [ "192.168.1.1" "8.8.8.8" ];
  #  bridges."br0".interfaces = [ "eth0" ];

  #  interfaces."br0".ipv4.addresses = [{
  #    address = "192.168.1.226";
  #    prefixLength = 24;
  #  }];
  #};
}