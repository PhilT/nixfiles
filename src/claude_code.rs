//! `nixx update-claude`: bump the claude-code overlay pin in
//! modules/development.nix to the latest published release, print the
//! changelog for the releases in the jump, then let the caller rebuild.

use anyhow::{Context, Result};

use crate::{system, Ctx};

/// The npm linux-x64 package is authoritative and matches the GCS bucket;
/// GitHub releases / the GCS stable pointer can lag behind it.
const NPM_LATEST: &str = "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-x64/latest";
const CHANGELOG_URL: &str = "https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md";
const GCS_BUCKET: &str =
    "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";

/// Update the pin. Returns true if development.nix was changed (so the caller
/// should rebuild), false if already up to date or running in dryrun.
pub fn update(ctx: &Ctx) -> Result<bool> {
    let dev_nix = ctx.app_dir.join("modules/development.nix");
    let text = std::fs::read_to_string(&dev_nix)
        .with_context(|| format!("reading {}", dev_nix.display()))?;

    let current = extract(&text, "version = \"")
        .context("no `version = \"...\"` line found in development.nix")?;
    let latest = fetch_latest_version()?;
    system::log("CLAUDE", &format!("current {current}, latest {latest}"));

    if latest == current {
        system::log("CLAUDE", "already up to date");
        return Ok(false);
    }

    let old_hash = extract(&text, "hash = \"")
        .context("no `hash = \"...\"` line found in development.nix")?;
    let new_hash = prefetch_hash(&latest)?;

    if ctx.dryrun {
        system::log("CLAUDE", &format!("would set version={latest} hash={new_hash}"));
    } else {
        let updated = text
            .replace(
                &format!("version = \"{current}\""),
                &format!("version = \"{latest}\""),
            )
            .replace(
                &format!("hash = \"{old_hash}\""),
                &format!("hash = \"{new_hash}\""),
            );
        std::fs::write(&dev_nix, updated)
            .with_context(|| format!("writing {}", dev_nix.display()))?;
    }

    println!("\nclaude-code: {current} → {latest}\n");
    print_changelog(&current, &latest);

    Ok(!ctx.dryrun)
}

/// Pull the value out of the first `<prefix>VALUE"` occurrence in `text`.
fn extract(text: &str, prefix: &str) -> Option<String> {
    let start = text.find(prefix)? + prefix.len();
    let rest = &text[start..];
    let end = rest.find('"')?;
    Some(rest[..end].to_string())
}

fn fetch_latest_version() -> Result<String> {
    let body: serde_json::Value = ureq::get(NPM_LATEST)
        .call()
        .context("fetching npm latest")?
        .into_json()
        .context("parsing npm response")?;
    body["version"]
        .as_str()
        .map(str::to_string)
        .context("npm response missing version")
}

/// Download the linux-x64 binary into the store and return its SRI hash.
fn prefetch_hash(version: &str) -> Result<String> {
    let url = format!("{GCS_BUCKET}/{version}/linux-x64/claude");
    let cmd = format!(
        "nix --extra-experimental-features nix-command store prefetch-file --json --name claude {}",
        system::sh_quote(&url)
    );
    let out = system::capture(&cmd, "CLAUDE")?;
    let json: serde_json::Value =
        serde_json::from_str(&out).context("parsing prefetch-file json")?;
    json["hash"]
        .as_str()
        .map(str::to_string)
        .context("prefetch-file output missing hash (version may not be in the GCS bucket yet)")
}

/// Print every changelog entry from the new heading down to (excluding) the
/// old one. The upstream CHANGELOG has one `## X.Y.Z` heading per release,
/// newest first, so this range is exactly the releases in the jump.
fn print_changelog(old: &str, new: &str) {
    let text = match fetch_changelog() {
        Ok(t) => t,
        Err(e) => {
            system::log("CLAUDE", &format!("changelog unavailable: {e:#}"));
            return;
        }
    };
    let new_head = format!("## {new}");
    let old_head = format!("## {old}");
    let mut printing = false;
    let mut any = false;
    for line in text.lines() {
        if line == new_head {
            printing = true;
        } else if line == old_head {
            break;
        }
        if printing {
            println!("{line}");
            any = true;
        }
    }
    if !any {
        system::log("CLAUDE", "no changelog entries found for this range");
    }
}

fn fetch_changelog() -> Result<String> {
    ureq::get(CHANGELOG_URL)
        .call()
        .context("fetching changelog")?
        .into_string()
        .context("reading changelog body")
}
