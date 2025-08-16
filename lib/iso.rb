module Iso
  def self.write
    run "nix-build", "'<nixpkgs/nixos>'", "-A", "config.system.build.isoImage", "-I", "nixos-config=iso.nix"
    FileUtils.cp "result/iso/*.iso", "/data/iso/nixos.iso"
    FileUtils.chmod "+w", "/data/iso/nixos.iso"
  end
end