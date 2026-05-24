#![allow(dead_code)]

//! Equivalent of lib/ssh.rb: manages SSH keys via the credentials file.
//!
//! The credentials YAML stores keys under:
//!   ssh:
//!     <service>:           # "local", "github", or arbitrary remote name
//!       <machine>:         # hostname or "all"
//!         <key_type>:      # "ed25519", "ecdsa"
//!           public: ...
//!           private: |-
//!             ...

use anyhow::{bail, Context, Result};
use rand::RngCore;
use serde_yml::{Mapping, Value};
use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};
use std::process::Command;

use crate::credentials::Credentials;

const TMP_PUBKEY_PREFIX: &str = "/tmp/id_ed25519_";

pub struct Ssh {
    pub overwrite: bool,
}

impl Ssh {
    pub fn new(overwrite: bool) -> Self {
        Self { overwrite }
    }

    /// Walks ssh_keys, generates a key for any (service, machine, type) triple
    /// that doesn't have a public key yet, and saves the credentials file.
    pub fn generate_all_keys(&self, creds: &mut Credentials) -> Result<()> {
        let mut dirty = false;
        let ssh = creds
            .yaml_mut()
            .get_mut("ssh")
            .context("no `ssh` block in credentials")?;
        let ssh = ssh.as_mapping_mut().context("ssh block is not a mapping")?;

        for (service_key, machines) in ssh.iter_mut() {
            let service = value_str(service_key);
            let machines = match machines.as_mapping_mut() {
                Some(m) => m,
                None => continue,
            };
            for (machine_key, key_types) in machines.iter_mut() {
                let machine = value_str(machine_key);
                let key_types = match key_types.as_mapping_mut() {
                    Some(m) => m,
                    None => continue,
                };
                for (type_key, keys) in key_types.iter_mut() {
                    let key_type = value_str(type_key);
                    let has_public = keys
                        .as_mapping()
                        .and_then(|m| m.get("public"))
                        .and_then(|v| v.as_str())
                        .map(|s| !s.is_empty())
                        .unwrap_or(false);

                    if has_public {
                        log_ssh(&format!("{key_type} key for {service}/{machine} exists"));
                    } else {
                        log_ssh(&format!("Generating {key_type} key for {service}/{machine}"));
                        let pair = generate_key_pair(&key_type)?;
                        *keys = pair.into_value();
                        dirty = true;
                    }
                }
            }
        }

        if dirty {
            creds.save()?;
        }
        Ok(())
    }

    /// Writes any matching keys from credentials into ssh_dir, creating the
    /// directory if needed. Skips keys for other machines.
    pub fn write_keys_to(&self, creds: &Credentials, machine: &str, ssh_dir: &Path) -> Result<()> {
        if ssh_dir.is_dir() {
            log_ssh(&format!("{} folder exists", ssh_dir.display()));
        } else {
            log_ssh(&format!("No SSH folder. Creating {}", ssh_dir.display()));
            std::fs::create_dir_all(ssh_dir)?;
            std::fs::set_permissions(ssh_dir, std::fs::Permissions::from_mode(0o700))?;
        }

        let ssh = creds.get(&["ssh"]).context("no `ssh` block in credentials")?;
        let ssh = ssh.as_mapping().context("ssh block is not a mapping")?;

        for (service_key, machines) in ssh {
            let service = value_str(service_key);
            let service_suffix = if service == "local" { String::new() } else { format!("_{service}") };
            let machines = match machines.as_mapping() {
                Some(m) => m,
                None => continue,
            };
            for (machine_key, key_types) in machines {
                let m = value_str(machine_key);
                if m != machine && m != "all" {
                    continue;
                }
                let key_types = match key_types.as_mapping() {
                    Some(t) => t,
                    None => continue,
                };
                for (type_key, keys) in key_types {
                    let key_type = value_str(type_key);
                    let keypath = ssh_dir.join(format!("id_{key_type}{service_suffix}"));
                    let keypath_pub = ssh_dir.join(format!("id_{key_type}{service_suffix}.pub"));

                    let public = keys
                        .get("public")
                        .and_then(|v| v.as_str())
                        .map(|s| s.to_owned());

                    if keypath_pub.exists() {
                        let existing = std::fs::read_to_string(&keypath_pub)?;
                        let same = match &public {
                            Some(p) => key_material(&existing) == key_material(p),
                            None => false,
                        };
                        if same {
                            if self.overwrite {
                                log_ssh(&format!("Overwriting {}", keypath.display()));
                            } else {
                                log_ssh(&format!("{} Matches existing key. Skipping", keypath.display()));
                                continue;
                            }
                        } else if self.overwrite {
                            log_ssh(&format!(
                                "{} does not match existing key. Overwriting",
                                keypath.display()
                            ));
                        } else {
                            log_ssh(&format!(
                                "{} does not match existing key. Specify --overwrite to overwrite",
                                keypath.display()
                            ));
                            continue;
                        }
                    } else if public.is_none() {
                        log_ssh(&format!(
                            "ssh.{service}.{m}.{key_type} is not set in credentials file. Skipping"
                        ));
                        continue;
                    }

                    let private = keys
                        .get("private")
                        .and_then(|v| v.as_str())
                        .context("missing private key")?;
                    let public = public.context("missing public key")?;
                    write_ssh_key(&keypath, &keypath_pub, &public, private)?;
                }
            }
        }
        Ok(())
    }

    /// Returns the public/private pair for a (service, machine, type) lookup.
    pub fn key_pair_for<'a>(
        &self,
        creds: &'a Credentials,
        service: &str,
        machine: &str,
        key_type: &str,
    ) -> Option<&'a Value> {
        creds.get(&["ssh", service, machine, key_type])
    }
}

/// RAII guard: drops public keys for every "local" machine into /tmp at
/// construction, removes them on Drop. Used by build / iso so the Nix
/// configuration can read them in.
pub struct PublicKeysGuard {
    paths: Vec<PathBuf>,
}

impl PublicKeysGuard {
    pub fn create(creds: &Credentials) -> Result<Self> {
        let mut paths = Vec::new();
        let local = match creds.get(&["ssh", "local"]).and_then(|v| v.as_mapping()) {
            Some(m) => m,
            None => return Ok(Self { paths }),
        };
        for (machine_key, key_types) in local {
            let machine = value_str(machine_key);
            let public = key_types
                .as_mapping()
                .and_then(|m| m.get("ed25519"))
                .and_then(|v| v.as_mapping())
                .and_then(|m| m.get("public"))
                .and_then(|v| v.as_str());
            match public {
                Some(p) => {
                    let path = PathBuf::from(format!("{TMP_PUBKEY_PREFIX}{machine}.pub"));
                    std::fs::write(&path, p)?;
                    paths.push(path);
                }
                None => log_ssh(&format!("No ed25519 keys for {machine}. Skipping")),
            }
        }
        Ok(Self { paths })
    }
}

impl Drop for PublicKeysGuard {
    fn drop(&mut self) {
        for path in &self.paths {
            let _ = std::fs::remove_file(path);
        }
    }
}

pub struct KeyPair {
    pub public: String,
    pub private: String,
}

impl KeyPair {
    fn into_value(self) -> Value {
        let mut map = Mapping::new();
        map.insert(Value::from("public"), Value::from(self.public));
        map.insert(Value::from("private"), Value::from(self.private));
        Value::Mapping(map)
    }
}

pub fn generate_key_pair(keytype: &str) -> Result<KeyPair> {
    let mut suffix = [0u8; 10];
    rand::thread_rng().fill_bytes(&mut suffix);
    let private_path = PathBuf::from(format!("/tmp/id_{keytype}{}", hex::encode(suffix)));
    let public_path = private_path.with_extension("pub");

    let status = Command::new("ssh-keygen")
        .args([
            "-q",
            "-t", keytype,
            "-a", "100",
            "-f", &private_path.to_string_lossy(),
            "-N", "",
        ])
        .status()
        .context("running ssh-keygen")?;
    if !status.success() {
        bail!("ssh-keygen failed (exit {:?})", status.code());
    }

    let private = std::fs::read_to_string(&private_path)?;
    let public_full = std::fs::read_to_string(&public_path)?;
    // Trim comment field — keep only "<type> <base64>"
    let public = public_full
        .split_whitespace()
        .take(2)
        .collect::<Vec<_>>()
        .join(" ");

    let _ = std::fs::remove_file(&private_path);
    let _ = std::fs::remove_file(&public_path);

    Ok(KeyPair { public, private })
}

fn write_ssh_key(keypath: &Path, keypath_pub: &Path, public: &str, private: &str) -> Result<()> {
    log_ssh(&format!("Writing to {} and {}", keypath.display(), keypath_pub.display()));
    std::fs::write(keypath, format!("{private}\n"))?;
    std::fs::write(keypath_pub, public)?;
    std::fs::set_permissions(keypath, std::fs::Permissions::from_mode(0o600))?;
    Ok(())
}

/// Returns the base64 portion of an "ssh-<type> <base64> [comment]" line —
/// the canonical key fingerprint material.
fn key_material(line: &str) -> Option<&str> {
    line.split_whitespace().nth(1)
}

fn value_str(v: &Value) -> String {
    v.as_str().map(|s| s.to_owned()).unwrap_or_else(|| serde_yml::to_string(v).unwrap_or_default().trim().to_owned())
}

fn log_ssh(msg: &str) {
    crate::system::log("SSH", msg);
}
