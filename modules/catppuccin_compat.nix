{ lib, ... }:
{
  # Catppuccin NixOS module references services.displayManager.generic which was
  # removed in NixOS 25.11. Declare it as a sink to prevent evaluation errors.
  options.services.displayManager.generic = lib.mkOption {
    type = lib.types.anything;
    default = {};
  };
}
