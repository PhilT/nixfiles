#![allow(dead_code)]

//! Equivalent of lib/zfs.rb. Only what's needed by `nixx build` is wired up.

use anyhow::Result;

use crate::system::{log, sudo_capture, sudo_prefix};

pub fn switch_to_key_based_encryption() -> Result<()> {
    log("ZFS", "Switching to key-based encryption");
    let pool_name = "dpool";
    let zfs_keydir = "/root";
    let zfs_keypath = format!("{zfs_keydir}/.{pool_name}.key");

    if !in_zpool(pool_name)? {
        log(pool_name, &format!("No {pool_name} pool. Skipping."));
        return Ok(());
    }

    // `sudo test -f` exits non-zero if missing — sudo_capture would bail. Use
    // a tolerant variant.
    let exists = std::process::Command::new("sh")
        .arg("-c")
        .arg(format!("{}test -f {zfs_keypath}", sudo_prefix()))
        .status()?
        .success();

    if exists {
        log(pool_name, &format!("{zfs_keypath} exists"));
    } else {
        log(
            pool_name,
            &format!("No {pool_name} encryption key at {zfs_keypath}. Creating and assigning"),
        );
        sudo_capture(&format!("mkdir -p {zfs_keydir}"), pool_name)?;
        sudo_capture(&format!("chmod 700 {zfs_keydir}"), pool_name)?;
        generate_key(&zfs_keypath)?;
        change_key(pool_name, &zfs_keypath)?;
    }
    Ok(())
}

pub fn in_zpool(pool_name: &str) -> Result<bool> {
    let out = std::process::Command::new("sh")
        .arg("-c")
        .arg("zpool list")
        .output()?;
    if !out.status.success() {
        return Ok(false);
    }
    Ok(String::from_utf8_lossy(&out.stdout).contains(pool_name))
}

fn generate_key(keyfile: &str) -> Result<()> {
    sudo_capture(&format!("dd if=/dev/urandom bs=32 count=1 of={keyfile}"), "ZFS")?;
    sudo_capture(&format!("chmod 400 {keyfile}"), "ZFS")?;
    Ok(())
}

fn change_key(pool_name: &str, keyfile: &str) -> Result<()> {
    sudo_capture(
        &format!(
            "zfs change-key -o keyformat=raw -o keylocation=file://{keyfile} {pool_name}"
        ),
        "ZFS",
    )?;
    Ok(())
}
