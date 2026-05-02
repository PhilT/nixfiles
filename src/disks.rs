#![allow(dead_code)]

//! Equivalent of lib/disks.rb. Loads machine partitioning from
//! config/machines.yml and orchestrates partitioning / pool creation.

use anyhow::{bail, Context, Result};
use serde_yml::Value;
use std::path::Path;

use crate::credentials::Credentials;
use crate::system::{log, sudo_capture, sudo_prefix, sudo_system, wait_for_input};
use crate::zfs::in_zpool;
use crate::Ctx;
use std::process::Command;

pub struct Disks<'a> {
    pub machine: String,
    pub wipe: bool,
    pub root: String,
    pub credentials: &'a Credentials,
    pub disks: Value,
}

impl<'a> Disks<'a> {
    pub fn load(app_dir: &Path, machine: &str, wipe: bool, root: &str, credentials: &'a Credentials) -> Result<Self> {
        let path = app_dir.join("config/machines.yml");
        if !path.exists() {
            bail!(
                "No config/machines.yml file found.\n\
                 Use config/machines.yml.example as a starting point."
            );
        }
        let text = std::fs::read_to_string(&path)
            .with_context(|| format!("reading {}", path.display()))?;
        let all: Value = serde_yml::from_str(&text).context("parsing machines.yml")?;
        let disks = all
            .get(machine)
            .cloned()
            .with_context(|| format!("no entry for `{machine}` in machines.yml"))?;
        Ok(Self {
            machine: machine.into(),
            wipe,
            root: root.into(),
            credentials,
            disks,
        })
    }

    pub fn more_than_one(&self) -> bool {
        self.disks.as_mapping().map(|m| m.len() > 1).unwrap_or(false)
    }

    pub fn partition(&self, ctx: &Ctx) -> Result<()> {
        let mapping = self.disks.as_mapping().context("disks block is not a mapping")?;
        for (_, disk) in mapping {
            self.rm_boot_entries(ctx, disk.get("boot"))?;
            self.create_boot_disk(ctx, disk.get("boot"))?;
            self.create_data_disk(ctx, disk.get("data").and_then(|d| d.get("device")))?;
            self.create_pool(ctx, disk.get("pool"))?;
            self.create_datasets(ctx, disk.get("pool"))?;
            self.create_fat(ctx, disk.get("boot"))?;
            self.create_directories(ctx, disk.get("pool").and_then(|p| p.get("directories")))?;
        }
        Ok(())
    }

    fn rm_boot_entries(&self, ctx: &Ctx, boot: Option<&Value>) -> Result<()> {
        let boot = match boot {
            Some(b) => b,
            None => return Ok(()),
        };
        if !self.wipe || !boot.get("remove_entries").and_then(|v| v.as_bool()).unwrap_or(false) {
            return Ok(());
        }
        log("BOOT", "Removing boot entries");
        let entries = sudo_capture("efibootmgr", "BOOT")?;
        for line in entries.lines().filter(|l| l.contains("Linux Boot Manager")) {
            let num = line
                .split_whitespace()
                .next()
                .and_then(|s| s.strip_prefix("Boot"))
                .map(|s| s.trim_end_matches('*').to_owned())
                .context("parsing efibootmgr line")?;
            sudo_system(ctx, &format!("efibootmgr -Bb {num}"), "BOOT")?;
        }
        Ok(())
    }

    fn create_boot_disk(&self, ctx: &Ctx, boot: Option<&Value>) -> Result<()> {
        let boot = match boot {
            Some(b) if self.wipe => b,
            _ => return Ok(()),
        };
        let device = boot
            .get("device")
            .and_then(|v| v.as_str())
            .context("boot.device missing")?;
        let size = boot
            .get("size")
            .and_then(|v| v.as_str())
            .context("boot.size missing")?;

        log("PART", "WARNING: This will destroy all your data!!!");
        wait_for_input(ctx, &format!("Press ENTER to repartition {device}"))?;

        log("PART", "Setup boot and primary partitions");
        sudo_system(ctx, &format!("sgdisk -Z {device}"), "PART")?;
        sudo_system(ctx, &format!("parted -s {device} -- mklabel gpt"), "PART")?;
        sudo_system(ctx, &format!("parted -s {device} -- mkpart ESP fat32 0% {size}"), "PART")?;
        sudo_system(ctx, &format!("parted -s {device} -- mkpart primary {size} 100%"), "PART")?;
        sudo_system(ctx, &format!("parted -s {device} -- set 1 boot on"), "PART")?;
        sudo_system(ctx, &format!("partprobe {device}"), "PART")?;
        Ok(())
    }

    fn create_data_disk(&self, ctx: &Ctx, device: Option<&Value>) -> Result<()> {
        let device = match device.and_then(|v| v.as_str()) {
            Some(d) if self.wipe => d,
            _ => return Ok(()),
        };
        log("PART", "WARNING: This will destroy all your data!!!");
        wait_for_input(ctx, &format!("Press ENTER to repartition {device}"))?;
        log("PART", "Setup data disk");
        sudo_system(ctx, &format!("sgdisk -Z {device}"), "PART")?;
        Ok(())
    }

    fn create_pool(&self, ctx: &Ctx, pool: Option<&Value>) -> Result<()> {
        let pool = match pool {
            Some(p) => p,
            None => return Ok(()),
        };
        let name = pool.get("name").and_then(|v| v.as_str()).context("pool.name missing")?;
        let partition = pool
            .get("partition")
            .and_then(|v| v.as_str())
            .context("pool.partition missing")?;
        let encryption = pool
            .get("encryption")
            .and_then(|v| v.as_str())
            .or_else(|| pool.get("encryption").and_then(|v| v.as_bool()).map(|b| if b { "on" } else { "off" }))
            .unwrap_or("off");

        let exists = in_zpool(name)?;
        if !self.wipe && exists {
            return Ok(());
        }

        log("POOL", "Setup ZFS pool");
        let action = if exists { "recreate" } else { "create" };
        log("PART", "WARNING: This will destroy all your data!!!");
        wait_for_input(ctx, &format!("Press ENTER to {action} zpool '{name}'"))?;

        let (password, encryption_opts): (Option<&str>, &str) = if encryption == "on" {
            let pw = self
                .credentials
                .get(&["disks", "encryption_password"])
                .and_then(|v| v.as_str())
                .context("missing disks.encryption_password in credentials")?;
            (
                Some(pw),
                " -O encryption=on -O keyformat=passphrase -O keylocation=prompt",
            )
        } else {
            (None, "")
        };

        let zpool_cmd = format!(
            "{}zpool create -f{encryption_opts} \
             -o ashift=12 -O atime=off -O compression=lz4 \
             -O mountpoint=none -O acltype=posixacl -O xattr=sa \
             {name} {partition}",
            sudo_prefix()
        );

        let log_msg = if password.is_some() {
            format!("echo <password> | {zpool_cmd}")
        } else {
            zpool_cmd.clone()
        };
        log("POOL", &log_msg);
        if ctx.dryrun {
            return Ok(());
        }

        let mut child = Command::new("sh")
            .arg("-c")
            .arg(&zpool_cmd)
            .stdin(std::process::Stdio::piped())
            .spawn()
            .context("spawning zpool create")?;
        if let Some(pw) = password {
            use std::io::Write;
            if let Some(stdin) = child.stdin.as_mut() {
                writeln!(stdin, "{pw}").ok();
            }
        }
        let status = child.wait()?;
        if !status.success() {
            anyhow::bail!("zpool create failed (exit {:?})", status.code());
        }
        Ok(())
    }

    fn create_datasets(&self, ctx: &Ctx, pool: Option<&Value>) -> Result<()> {
        let pool = match pool {
            Some(p) => p,
            None => return Ok(()),
        };
        let datasets = match pool.get("datasets").and_then(|v| v.as_sequence()) {
            Some(d) => d,
            None => return Ok(()),
        };
        let pool_name = pool.get("name").and_then(|v| v.as_str()).context("pool.name missing")?;
        let names: Vec<String> = datasets
            .iter()
            .filter_map(|v| v.as_str().map(String::from))
            .collect();
        log("DATASET", &format!("Setup datasets: {}", names.join(", ")));

        let existing = sudo_capture("zfs list", "DATASET").unwrap_or_default();

        for name in &names {
            let dataset = format!("{pool_name}/{name}");
            let mountpoint = if name == "root" {
                self.root.clone()
            } else {
                format!("{}{name}", self.root)
            };

            if !existing.contains(&dataset) {
                sudo_system(ctx, &format!("zfs create -o mountpoint=legacy {dataset}"), "DATASET")?;
                sudo_system(ctx, &format!("zfs snapshot {dataset}@blank"), "DATASET")?;
            } else {
                log("DATASET", &format!("{dataset} exists. Skipping"));
            }

            sudo_system(ctx, &format!("mkdir -p {mountpoint}"), "DATASET")?;
            safe_mount(ctx, &dataset, &mountpoint, Some("zfs"))?;
        }
        Ok(())
    }

    fn create_fat(&self, ctx: &Ctx, boot: Option<&Value>) -> Result<()> {
        let boot = match boot {
            Some(b) => b,
            None => return Ok(()),
        };
        let device = boot.get("device").and_then(|v| v.as_str()).context("boot.device missing")?;
        let partition = boot
            .get("partition")
            .and_then(|v| v.as_str())
            .context("boot.partition missing")?;
        let boot_partition = format!("{device}{partition}");

        if self.wipe {
            log("PART", "WARNING: This will destroy all your data!!!");
            wait_for_input(ctx, &format!("Press ENTER to format {boot_partition}"))?;
            sudo_system(ctx, &format!("mkfs.vfat -n boot {boot_partition} > /dev/null"), "PART")?;
        }

        let mount = format!("{}boot", self.root);
        sudo_system(ctx, &format!("mkdir -p {mount}"), "PART")?;
        safe_mount(ctx, &boot_partition, &mount, None)?;
        Ok(())
    }

    fn create_directories(&self, ctx: &Ctx, directories: Option<&Value>) -> Result<()> {
        let directories = match directories.and_then(|v| v.as_sequence()) {
            Some(d) => d,
            None => return Ok(()),
        };
        for dir in directories {
            let dir = match dir.as_str() {
                Some(s) => s,
                None => continue,
            };
            sudo_system(ctx, &format!("mkdir -p {}{dir}", self.root), "PART")?;
        }
        Ok(())
    }
}

fn safe_mount(ctx: &Ctx, device: &str, target: &str, fstype: Option<&str>) -> Result<()> {
    if !ctx.dryrun && is_mountpoint(target) {
        return Ok(());
    }
    let type_arg = match fstype {
        Some(t) => format!("-t {t} "),
        None => String::new(),
    };
    sudo_system(ctx, &format!("mount {type_arg}{device} {target}"), "MOUNT")
}

fn is_mountpoint(target: &str) -> bool {
    std::process::Command::new("sh")
        .arg("-c")
        .arg(format!("mountpoint -q {target}"))
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
}

