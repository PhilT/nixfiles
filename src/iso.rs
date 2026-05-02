//! Equivalent of lib/iso.rb: builds a NixOS install ISO.

use anyhow::{bail, Context, Result};
use std::os::unix::fs::PermissionsExt;
use std::path::Path;

use crate::system;
use crate::Ctx;

const OUTPUT_PATH: &str = "/data/iso/nixos.iso";

pub fn build(ctx: &Ctx) -> Result<()> {
    let cmd = "nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=iso.nix";
    system::run_system(ctx, cmd, "ISO")?;

    if ctx.dryrun {
        return Ok(());
    }

    let result_dir = ctx.app_dir.join("result/iso");
    let iso = std::fs::read_dir(&result_dir)
        .with_context(|| format!("reading {}", result_dir.display()))?
        .filter_map(|e| e.ok())
        .map(|e| e.path())
        .find(|p| p.extension().and_then(|s| s.to_str()) == Some("iso"))
        .with_context(|| format!("no .iso file in {}", result_dir.display()))?;

    let dest = Path::new(OUTPUT_PATH);
    if let Some(parent) = dest.parent() {
        std::fs::create_dir_all(parent).ok();
    }
    std::fs::copy(&iso, dest).with_context(|| format!("copying {} to {}", iso.display(), dest.display()))?;

    let mut perms = std::fs::metadata(dest)?.permissions();
    perms.set_mode(perms.mode() | 0o200);
    std::fs::set_permissions(dest, perms)?;

    if !dest.exists() {
        bail!("ISO did not appear at {OUTPUT_PATH}");
    }
    Ok(())
}
