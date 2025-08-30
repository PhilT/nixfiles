module Iso
  def writeIso(root_dir)
    run "nix-build", "'<nixpkgs/nixos>'", "-A", "config.system.build.isoImage", "-I", "nixos-config=iso.nix", use_system: true
    iso_path = Dir[File.join(root_dir, "result/iso/*.iso")].first
    FileUtils.cp iso_path, "/data/iso/nixos.iso"
    FileUtils.chmod "+w", "/data/iso/nixos.iso"
  end
end