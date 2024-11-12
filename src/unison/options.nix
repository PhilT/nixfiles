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
    };
  };
}