# Imported by iso.nix and minimal.nix
{ config, pkgs, ... }: {
  environment = {
    sessionVariables = {
      GEM_PATH = "/run/current-system/sw/lib/ruby/gems/3.4.0";
    };

    systemPackages = with pkgs; [
      curl
      gcc
      git
      git-filter-repo
      gnumake
      htop
      libyaml
      lsof
      pkg-config
      ruby_3_4
      wget
      which

      # Ruby gems for nixx added here so they're available when bootstrapping
      # a new machine. Version numbers match the Gemfile.
      # See Gemfile if changing these.
      rubyPackages_3_4.activesupport
      rubyPackages_3_4.rake
      rubyPackages_3_4.thor
    ];
  };
}