{ lib, config, ... }: {
  options = {
    vulkan.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Generally for toggling off on VMs until Qemu comes with virgl venus support";
    };

    ssh.preventRootLogin = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Avoids a conflict with iso.nix that sets PermitRootLogin to yes";
    };

    machine = lib.mkOption {
      type = lib.types.str;
    };

    username = lib.mkOption {
      type = lib.types.str;
    };

    fullname = lib.mkOption {
      type = lib.types.str;
    };

    luks.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "LUKS disk encryption";
    };

    luks.device = lib.mkOption {
      type = lib.types.str;
      default = "/dev/nvme0n1p2";
    };

    # TODO: Can be removed once Spruce has been migrated to use separate /nix partition
    nixfs.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Separate the /nix store for improved SSD lifespan";
    };

    # The following options relating to transient or persisted storage
    # will only take affect once the machine is using ./ephemeral_os.nix.
    # These default locations will not be wiped on boot.
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/data";
      description = "Location of main data partition";
    };

    homeDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/${config.username}";
      description = "User's home folder (wiped on boot)";
    };

    # Synced with server and propagated to other machines
    persistedHomeDir = lib.mkOption {
      type = lib.types.str;
      default = config.homeDir;
      description = "User's home folder (persisted on boot)";
    };

    # Not synced with server
    persistedMachineDir = lib.mkOption {
      type = lib.types.str;
      default = config.homeDir;
      description = "Machine specific home folder (persisted on boot)";
    };

    codeDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.dataDir}/code";
      description = "Location of source code dir";
    };

    etcDir = lib.mkOption {
      type = lib.types.str;
      default = "/etc";
      description = "Location of persisted /etc";
    };

    varDir = lib.mkOption {
      type = lib.types.str;
      default = "/var";
      description = "Location of persisted /var";
    };

    xdgConfigHome = lib.mkOption {
      type = lib.types.str;
      default = "${config.homeDir}/.config";
      description = "XDG_CONFIG_HOME wiped on boot";
    };

    xdgDataHome = lib.mkOption {
      type = lib.types.str;
      default = "${config.homeDir}/.local/share";
      description = "Standard XDG_DATA_HOME";
    };

    waybarModules = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      description = "What Waybar modules to show";
    };
  };
}