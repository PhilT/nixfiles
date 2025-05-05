# https://astrid.tech/2022/09/22/0/nixos-gpu-vfio/
# udevadm monitor

{ config, lib, pkgs, ... }:
let
  vendor = "10de";
  gpu = "2684";
  audio = "22ba";
  gpuIds = "${vendor}:${gpu},${vendor}:${audio}";
  ovmfSecureBoot = pkgs.OVMF.overrideAttrs (final: prev: {
    pname = prev.pname + "-secure-boot";
    secureBoot = true;
    msVarsTemplate = true;
  });
in {
  #environment.etc."qemu/bridge.conf".text = "allow br0\n";
  environment.sessionVariables = {
    OVMF_NIX_DIR = "${pkgs.OVMF.fd}/FV";
    OVMF_MS_DIR = "${ovmfSecureBoot.fd}/FV";
  };
  environment.systemPackages = with pkgs;[
    OVMF                      # For NixOS
    ovmfSecureBoot            # For Windows
    qemu
    swtpm
    socat                     # For sending commands to Qemu via a socket

    # TODO: Probably don't need this any more
    (writeShellScriptBin "qemu-system-x86_64-uefi" ''
      qemu-system-x86_64 \
        -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
        "$@"
    '')

    # vm-cmd <seedling|sapling> <save|restore>
    (writeShellScriptBin "vm-cmd" ''
      machine=$1
      cmd=$2
      {
        echo '{"execute":"qmp_capabilities"}';
        sleep 0.1;  # Optional short delay to ensure order
        echo '{"execute":"human-monitor-command","arguments":{"command-line":"''${cmd} /data/vdisks/''${machine}_snapshot"}}';
      } | socat UNIX-CONNECT:/tmp/$${machine}-qmp.sock -
    '')
  ];

  systemd.extraConfig = ''
    DefaultLimitMEMLOCK=infinity
  '';

  boot.kernelParams = [
    "intel_iommu=on"
  ];

  boot.extraModprobeConfig = ''
    options vfio-pci ids=${gpuIds}
  '';

  boot.kernelModules = [ "vfio_pci" "vfio" "vfio_iommu_type1" "kvm-intel" ];

  # These rules only apply to connected devices. E.g. If my wheel is off it won't apply the permissions
  # This requires Sway to be started as a systemd service so that it's managed properly
  services.udev.extraRules = ''
    SUBSYSTEM=="vfio", TAG+="uaccess"
    SUBSYSTEM=="usb", TAG+="uaccess"
  '';

  users.groups.vfio = {};
  users.groups.hugepages = {};
  users.users."${config.username}".extraGroups = [
    "kvm"
    "vfio"
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