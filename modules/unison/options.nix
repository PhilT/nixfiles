{ lib, config, ... }: {
  options = {
    unison = {
      target = lib.mkOption {
        type = lib.types.str;
        description = "Machine name to sync to";
      };

      paths = lib.mkOption {
        type = with lib.types; listOf str;
        description = "Paths to sync";
      };

      extraConfig = lib.mkOption {
        type = lib.types.str;
        description = "Additional config to add to PRF file";
        default = "";
      };

      repeat = lib.mkOption {
        type = lib.types.str;
        description = "Unison repeat mode: \"watch\" for fsmonitor-driven sync, or an interval in seconds between full scans";
        default = "watch";
      };

      waitFor = lib.mkOption {
        type = with lib.types; listOf str;
        description = "Used as the after directive in the Unison systemd service";
        default = [ "network-online.target" ];
      };
    };
  };
}