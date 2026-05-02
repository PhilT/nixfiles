//! Equivalent of lib/settings.rb: loads config/settings.yml.
//!
//! Not yet wired up to a subcommand — used once `setup` is ported.

#![allow(dead_code)]

use anyhow::{Context, Result};
use serde::Deserialize;
use std::path::Path;

#[derive(Debug, Deserialize)]
pub struct Settings {
    pub repo: String,
}

impl Settings {
    pub fn load(app_dir: &Path) -> Result<Self> {
        let path = app_dir.join("config/settings.yml");
        let text = std::fs::read_to_string(&path)
            .with_context(|| format!("reading {}", path.display()))?;
        serde_yml::from_str(&text).with_context(|| format!("parsing {}", path.display()))
    }
}
