//! Equivalent of lib/credentials.rb.
//!
//! Wire-compatible with `ActiveSupport::EncryptedFile` from Rails 7.x:
//!
//! - File body: `<ciphertext>--<iv>--<auth_tag>`, each part standard-base64
//!   (with padding), separator literal `--`.
//! - Cipher: AES-128-GCM, key = hex-decoded master.key, IV = 12 random bytes,
//!   auth_tag = 16 bytes, auth_data empty.
//! - Plaintext layer: Marshal-dumped UTF-8 string.

#![allow(dead_code)]

use aes_gcm::aead::{Aead, KeyInit, Payload};
use aes_gcm::{Aes128Gcm, Nonce};
use anyhow::{bail, Context, Result};
use base64::{engine::general_purpose::STANDARD, Engine};
use rand::RngCore;
use std::path::{Path, PathBuf};

use crate::marshal;

const SEPARATOR: &str = "--";
const ENV_KEY: &str = "NIXX_MASTER_KEY";
const IV_LEN: usize = 12;
const TAG_LEN: usize = 16;

pub struct Credentials {
    content_path: PathBuf,
    key: [u8; 16],
    yaml: serde_yml::Value,
}

impl Credentials {
    pub fn load(app_dir: &Path) -> Result<Self> {
        let content_path = app_dir.join("config/credentials.yml.enc");
        let key_path = app_dir.join("config/master.key");
        let key = read_master_key(&key_path)?;

        let plaintext = if content_path.exists() {
            decrypt_file(&content_path, &key)?
        } else {
            String::new()
        };

        let yaml: serde_yml::Value = if plaintext.is_empty() {
            serde_yml::Value::Null
        } else {
            serde_yml::from_str(&plaintext).context("parsing decrypted YAML")?
        };

        Ok(Self { content_path, key, yaml })
    }

    pub fn show(&self) -> Result<String> {
        let text = std::fs::read(&self.content_path)
            .with_context(|| format!("reading {}", self.content_path.display()))?;
        let plaintext = decrypt_bytes(&text, &self.key)?;
        Ok(plaintext)
    }

    pub fn write_yaml(&self, yaml: &str) -> Result<()> {
        let ciphertext = encrypt(yaml.as_bytes(), &self.key)?;
        let tmp = self.content_path.with_extension("enc.tmp");
        std::fs::write(&tmp, &ciphertext)
            .with_context(|| format!("writing {}", tmp.display()))?;
        std::fs::rename(&tmp, &self.content_path)?;
        Ok(())
    }

    pub fn get<'a>(&'a self, path: &[&str]) -> Option<&'a serde_yml::Value> {
        let mut cur = &self.yaml;
        for key in path {
            cur = cur.get(*key)?;
        }
        Some(cur)
    }

    pub fn yaml(&self) -> &serde_yml::Value {
        &self.yaml
    }

    pub fn yaml_mut(&mut self) -> &mut serde_yml::Value {
        &mut self.yaml
    }

    /// Serialise the in-memory YAML and re-encrypt to disk.
    pub fn save(&self) -> Result<()> {
        let yaml = serde_yml::to_string(&self.yaml).context("serialising credentials YAML")?;
        self.write_yaml(&yaml)
    }

    /// Drops the hashed password into /tmp/hashed_password for the duration
    /// of the returned guard. Used by nixos-rebuild so users.users.<x>.hashedPasswordFile
    /// can read it during evaluation.
    pub fn with_hashed_password(&self) -> Result<HashedPasswordGuard> {
        let hashed = self
            .get(&["hashed_password"])
            .and_then(|v| v.as_str())
            .context("hashed_password missing from credentials")?;
        let path = std::path::PathBuf::from("/tmp/hashed_password");
        std::fs::write(&path, hashed)?;
        Ok(HashedPasswordGuard { path })
    }
}

pub struct HashedPasswordGuard {
    path: std::path::PathBuf,
}

impl Drop for HashedPasswordGuard {
    fn drop(&mut self) {
        let _ = std::fs::remove_file(&self.path);
    }
}

fn read_master_key(key_path: &Path) -> Result<[u8; 16]> {
    let hex_key = match std::env::var(ENV_KEY) {
        Ok(v) if !v.trim().is_empty() => v.trim().to_owned(),
        _ => {
            let bytes = std::fs::read(key_path)
                .with_context(|| format!("reading master key at {}", key_path.display()))?;
            String::from_utf8(bytes)
                .context("master key is not valid UTF-8")?
                .trim()
                .to_owned()
        }
    };
    if hex_key.len() != 32 {
        bail!("master key must be 32 hex chars (got {})", hex_key.len());
    }
    let raw = hex::decode(&hex_key).context("master key is not valid hex")?;
    let mut out = [0u8; 16];
    out.copy_from_slice(&raw);
    Ok(out)
}

fn decrypt_file(path: &Path, key: &[u8; 16]) -> Result<String> {
    let raw = std::fs::read(path).with_context(|| format!("reading {}", path.display()))?;
    decrypt_bytes(&raw, key)
}

fn decrypt_bytes(raw: &[u8], key: &[u8; 16]) -> Result<String> {
    let text = std::str::from_utf8(raw)
        .context("encrypted file is not valid UTF-8")?
        .trim();
    let parts: Vec<&str> = text.split(SEPARATOR).collect();
    if parts.len() != 3 {
        bail!("expected 3 base64 parts separated by '--', got {}", parts.len());
    }
    let ciphertext = STANDARD.decode(parts[0]).context("base64 ciphertext")?;
    let iv = STANDARD.decode(parts[1]).context("base64 iv")?;
    let tag = STANDARD.decode(parts[2]).context("base64 tag")?;
    if iv.len() != IV_LEN {
        bail!("iv must be {IV_LEN} bytes, got {}", iv.len());
    }
    if tag.len() != TAG_LEN {
        bail!("auth tag must be {TAG_LEN} bytes, got {}", tag.len());
    }

    // aes-gcm expects ciphertext || tag concatenated.
    let mut combined = ciphertext;
    combined.extend_from_slice(&tag);

    let cipher = Aes128Gcm::new_from_slice(key).expect("key length checked");
    let nonce = Nonce::from_slice(&iv);
    let plaintext = cipher
        .decrypt(nonce, Payload { msg: &combined, aad: b"" })
        .map_err(|_| anyhow::anyhow!("AES-GCM decryption failed (bad key or corrupt file)"))?;

    marshal::load_utf8_string(&plaintext)
}

fn encrypt(yaml: &[u8], key: &[u8; 16]) -> Result<Vec<u8>> {
    let marshaled = marshal::dump_utf8_string(std::str::from_utf8(yaml)?);

    let mut iv = [0u8; IV_LEN];
    rand::thread_rng().fill_bytes(&mut iv);

    let cipher = Aes128Gcm::new_from_slice(key).expect("key length checked");
    let nonce = Nonce::from_slice(&iv);
    let combined = cipher
        .encrypt(nonce, Payload { msg: &marshaled, aad: b"" })
        .map_err(|e| anyhow::anyhow!("AES-GCM encryption failed: {e}"))?;

    // Split ciphertext || tag.
    let split_at = combined.len() - TAG_LEN;
    let (ciphertext, tag) = combined.split_at(split_at);

    let body = format!(
        "{}{SEPARATOR}{}{SEPARATOR}{}",
        STANDARD.encode(ciphertext),
        STANDARD.encode(iv),
        STANDARD.encode(tag),
    );
    Ok(body.into_bytes())
}

pub fn cmd_show(app_dir: &Path) -> Result<()> {
    let creds = Credentials::load(app_dir)?;
    let text = creds.show()?;
    print!("{text}");
    Ok(())
}

pub fn cmd_edit(app_dir: &Path) -> Result<()> {
    use std::io::Read;

    let editor = std::env::var("EDITOR")
        .ok()
        .filter(|s| !s.is_empty())
        .context("EDITOR environment variable not set")?;

    let creds = Credentials::load(app_dir)?;
    let plaintext = if creds.content_path.exists() {
        creds.show()?
    } else {
        std::fs::read_to_string(app_dir.join("config/credentials.yml.example"))
            .context("reading credentials.yml.example for initial content")?
    };

    let mut tmp = tempfile::Builder::new()
        .prefix("credentials")
        .suffix(".yml")
        .tempfile()
        .context("creating tempfile")?;
    std::io::Write::write_all(tmp.as_file_mut(), plaintext.as_bytes())?;
    tmp.as_file_mut().sync_all()?;

    let status = std::process::Command::new("sh")
        .arg("-c")
        .arg(format!("{editor} {}", tmp.path().display()))
        .status()
        .context("running editor")?;
    if !status.success() {
        bail!("editor exited with non-zero status");
    }

    let mut updated = String::new();
    std::fs::File::open(tmp.path())?.read_to_string(&mut updated)?;
    serde_yml::from_str::<serde_yml::Value>(&updated).context("YAML error")?;

    creds.write_yaml(&updated)?;
    println!("[CREDS     ] Updated");
    Ok(())
}
