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
            .context("hashed_password missing from credentials — run `nixx credentials regenerate-hashed`")?;
        warn_if_hash_differs_from_system(hashed);
        let path = std::path::PathBuf::from("/tmp/hashed_password");
        std::fs::write(&path, hashed)?;
        Ok(HashedPasswordGuard { path })
    }
}

/// If the credentials hash differs from the live hash in /etc/shadow for the
/// current user, print rotation reminders. Best-effort: needs cached sudo to
/// read shadow; if we can't, stay silent.
fn warn_if_hash_differs_from_system(current: &str) {
    let Ok(user) = std::env::var("USER") else { return };
    let output = std::process::Command::new("sudo")
        .args(["-n", "getent", "shadow", &user])
        .output();
    let Ok(out) = output else { return };
    if !out.status.success() {
        return;
    }
    let line = String::from_utf8_lossy(&out.stdout);
    let Some(system_hash) = line.split(':').nth(1) else { return };
    if system_hash.trim() == current.trim() {
        return;
    }
    println!();
    println!("[CREDS     ] hashed_password differs from /etc/shadow on this machine.");
    println!("If main_password rotated, you may also need to:");
    for dev in luks_devices() {
        println!("  - LUKS disk: sudo cryptsetup luksAddKey {dev}");
        println!("               (reboot to verify, then luksRemoveKey for the old slot)");
    }
    for root in zfs_encryption_roots() {
        println!("  - ZFS:       sudo zfs change-key {root}");
    }
    println!("  - KeePassXC: keepassxc-cli db-edit --set-password /data/sync/HomeDatabase.kdbx");
    println!();
}

/// Return the underlying block devices for any active LUKS volumes.
fn luks_devices() -> Vec<String> {
    let Ok(out) = std::process::Command::new("lsblk")
        .args(["-l", "-p", "-n", "-o", "FSTYPE,NAME"])
        .output()
    else {
        return Vec::new();
    };
    if !out.status.success() {
        return Vec::new();
    }
    let mut devs: Vec<String> = String::from_utf8_lossy(&out.stdout)
        .lines()
        .filter_map(|l| {
            let mut parts = l.split_whitespace();
            let fstype = parts.next()?;
            let name = parts.next()?;
            (fstype == "crypto_LUKS").then(|| name.to_owned())
        })
        .collect();
    devs.sort();
    devs.dedup();
    devs
}

/// Return the encryption-root datasets on this machine (best-effort).
fn zfs_encryption_roots() -> Vec<String> {
    let Ok(out) = std::process::Command::new("zfs")
        .args(["get", "-H", "-o", "name,value", "encryptionroot"])
        .output()
    else {
        return Vec::new();
    };
    if !out.status.success() {
        return Vec::new();
    }
    let mut roots: Vec<String> = String::from_utf8_lossy(&out.stdout)
        .lines()
        .filter_map(|l| {
            let mut parts = l.split('\t');
            let name = parts.next()?;
            let root = parts.next()?;
            (name == root).then(|| name.to_owned())
        })
        .collect();
    roots.sort();
    roots.dedup();
    roots
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

const SSH_KEY_TYPES: &[&str] = &["ed25519", "ecdsa", "rsa", "dsa"];

struct RotateTask {
    path: Vec<String>,
    keytype: String,
}

pub fn cmd_rotate(app_dir: &Path, key: &str) -> Result<()> {
    let mut creds = Credentials::load(app_dir)?;
    let path: Vec<String> = key.split('.').map(str::to_owned).collect();
    let path_refs: Vec<&str> = path.iter().map(String::as_str).collect();
    let target = creds
        .get(&path_refs)
        .with_context(|| format!("key not found: {key}"))?
        .clone();

    let mut tasks: Vec<RotateTask> = Vec::new();
    collect_rotatables(&target, path.clone(), &mut tasks);

    if tasks.is_empty() {
        bail!("nothing rotatable at {key}: no ssh keypairs found under this path");
    }

    if tasks.len() > 1 {
        println!("Will rotate {} ssh keypairs under {key}:", tasks.len());
        for t in &tasks {
            println!("  {} (ssh {})", t.path.join("."), t.keytype);
        }
        print!("Proceed? [y/N] ");
        use std::io::Write;
        std::io::stdout().flush().ok();
        let mut answer = String::new();
        std::io::stdin().read_line(&mut answer)?;
        if !matches!(answer.trim(), "y" | "Y" | "yes") {
            println!("Aborted.");
            return Ok(());
        }
    }

    let mut pubkeys: Vec<(String, String)> = Vec::new();
    for task in tasks {
        let refs: Vec<&str> = task.path.iter().map(String::as_str).collect();
        let dotted = task.path.join(".");
        let pair = crate::ssh::generate_key_pair(&task.keytype)?;
        let mut map = serde_yml::Mapping::new();
        map.insert(serde_yml::Value::from("public"), serde_yml::Value::from(pair.public.clone()));
        map.insert(serde_yml::Value::from("private"), serde_yml::Value::from(pair.private));
        set_at_path(creds.yaml_mut(), &refs, serde_yml::Value::Mapping(map))?;
        pubkeys.push((dotted.clone(), pair.public));
        println!("Rotated {dotted}");
    }
    creds.save()?;

    for (k, pub_) in pubkeys {
        println!("  {k} public: {pub_}");
    }
    Ok(())
}

/// Walk `node` under `path` and append every ssh keypair found to `out`.
fn collect_rotatables(
    node: &serde_yml::Value,
    path: Vec<String>,
    out: &mut Vec<RotateTask>,
) {
    let refs: Vec<&str> = path.iter().map(String::as_str).collect();

    if is_ssh_keypair(&refs, node) {
        let keytype = path.last().cloned().unwrap_or_default();
        out.push(RotateTask { path, keytype });
        return;
    }
    let Some(map) = node.as_mapping() else { return };
    for (k, v) in map {
        let Some(name) = k.as_str() else { continue };
        let mut child = path.clone();
        child.push(name.to_owned());
        collect_rotatables(v, child, out);
    }
}

/// A value qualifies as an SSH keypair if the leaf path segment is a known
/// key type and the value is a mapping containing both `public` and `private`.
fn is_ssh_keypair(path: &[&str], value: &serde_yml::Value) -> bool {
    let Some(&leaf) = path.last() else { return false };
    if !SSH_KEY_TYPES.contains(&leaf) {
        return false;
    }
    let Some(map) = value.as_mapping() else { return false };
    map.contains_key(serde_yml::Value::from("public"))
        && map.contains_key(serde_yml::Value::from("private"))
}

/// Hash `main_password` with `mkpasswd -m yescrypt` and write the result to the
/// `hashed_password` field, overwriting any existing value.
pub fn cmd_regenerate_hashed(app_dir: &Path) -> Result<()> {
    use std::io::Write;
    use std::process::{Command, Stdio};

    let mut creds = Credentials::load(app_dir)?;
    let password = creds
        .get(&["main_password"])
        .and_then(|v| v.as_str())
        .context("main_password missing from credentials")?
        .to_owned();

    let mut child = Command::new("mkpasswd")
        .args(["-m", "yescrypt", "-s"])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::inherit())
        .spawn()
        .context("spawning mkpasswd (is it installed?)")?;
    child
        .stdin
        .as_mut()
        .context("mkpasswd stdin")?
        .write_all(password.as_bytes())?;
    let output = child.wait_with_output().context("waiting on mkpasswd")?;
    if !output.status.success() {
        bail!("mkpasswd exited with status {}", output.status);
    }
    let hashed = String::from_utf8(output.stdout)
        .context("mkpasswd output not UTF-8")?
        .trim()
        .to_owned();
    if hashed.is_empty() {
        bail!("mkpasswd produced empty output");
    }

    let root = creds
        .yaml_mut()
        .as_mapping_mut()
        .context("credentials root is not a mapping")?;
    root.insert(
        serde_yml::Value::from("hashed_password"),
        serde_yml::Value::from(hashed),
    );
    creds.save()?;
    println!("[CREDS     ] Regenerated hashed_password");
    Ok(())
}

/// Replace the value at `path` in the YAML tree. Errors if any intermediate
/// node is missing or not a mapping.
fn set_at_path(root: &mut serde_yml::Value, path: &[&str], value: serde_yml::Value) -> Result<()> {
    if path.is_empty() {
        bail!("cannot rotate the root document");
    }
    let mut cur = root;
    for &segment in &path[..path.len() - 1] {
        cur = cur
            .as_mapping_mut()
            .with_context(|| format!("path segment '{segment}' parent is not a mapping"))?
            .get_mut(serde_yml::Value::from(segment))
            .with_context(|| format!("path segment '{segment}' not found"))?;
    }
    let leaf = path.last().unwrap();
    cur.as_mapping_mut()
        .with_context(|| format!("leaf parent of '{leaf}' is not a mapping"))?
        .insert(serde_yml::Value::from(*leaf), value);
    Ok(())
}

pub fn cmd_show(app_dir: &Path, key: &str) -> Result<()> {
    let creds = Credentials::load(app_dir)?;
    let path: Vec<&str> = key.split('.').collect();
    let value = creds
        .get(&path)
        .with_context(|| format!("key not found: {key}"))?;
    match value {
        serde_yml::Value::String(s) => println!("{s}"),
        serde_yml::Value::Bool(b) => println!("{b}"),
        serde_yml::Value::Number(n) => println!("{n}"),
        serde_yml::Value::Null => println!(),
        other => {
            let yaml = serde_yml::to_string(other).context("serialising value")?;
            print!("{yaml}");
        }
    }
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
