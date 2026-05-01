{ pkgs, ... }: {
  environment = {
    sessionVariables = {
      VST_PATH = "/run/current-system/sw/lib/vst/";
      VST3_PATH = "/run/current-system/sw/lib/vst3/";
    };

    systemPackages = with pkgs; [
      (callPackage ./renoise.nix {})
      #surge-XT
      #stochas
      #lsp-plugins
      #odin2
      #cardinal
      #fire

      # VST plugins
      #(callPackage ./vst/sala.nix {})
      #(callPackage ./vst/argotlunar.nix {})
    ];
  };
}