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

    programs.kitty.fontSize = lib.mkOption {
      type = lib.types.int;
      default = 10;
      description = "Set the font size in Kitty";
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

    userHome = lib.mkOption {
      type = lib.types.str;
      default = "/home/${config.username}";
      description = "User's home folder";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/data";
      description = "Location of main data partition";
    };

    codeDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.dataDir}/code";
      description = "Location of source code dir";
    };

    xdgConfigHome = lib.mkOption {
      type = lib.types.str;
      default = "${config.userHome}/.config";
      description = "Standard XDG_CONFIG_HOME";
    };

    xdgDataHome = lib.mkOption {
      type = lib.types.str;
      default = "${config.userHome}/.local/share";
      description = "Standard XDG_DATA_HOME";
    };

    waybarModules = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      description = "What Waybar modules to show";
    };
  };
}