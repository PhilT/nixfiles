{ pkgs, ... }: {
  imports = [
    <catppuccin/modules/nixos>
  ];

  # rustc 1.95 (LLVM 21.1.8) segfaults in ScalarEvolution while fat-LTO-ing
  # catppuccin's whiskers, which every port needs at build time. Compiling
  # without LTO avoids the crashing pass.
  catppuccin.sources = (import <catppuccin> { inherit pkgs; }).packages.overrideScope (
    _final: prev: {
      whiskers = prev.whiskers.overrideAttrs (old: {
        env = (old.env or { }) // { CARGO_PROFILE_RELEASE_LTO = "off"; };
      });
    }
  );
}
