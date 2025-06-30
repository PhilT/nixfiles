{ pkgs, ... }: {
  environment = {
    # sessionVariables = {
    #   VST_PATH = "/run/current-system/sw/lib/vst/";
    #   VST3_PATH = "/run/current-system/sw/lib/vst3/";
    # };

    systemPackages = with pkgs; [
      renoise
      sunvox
      # surge-XT
      # stochas
      # librearp
      # lsp-plugins
      # odin2
      # cardinal
      # fire

      # VST plugins
      # (callPackage ./vst/sala.nix {})
      # (callPackage ./vst/ot_piano_s.nix {})
      # (callPackage ./vst/argotlunar.nix {})
      # (callPackage ./vst/excite_snare_drum.nix {})
    ];
  };
}