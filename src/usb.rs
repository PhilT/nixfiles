//! Equivalent of lib/usb.rb: writes a built ISO to a USB stick.

use anyhow::Result;
use std::path::Path;

use crate::system::{log, sudo_prefix, sudo_system};
use crate::Ctx;

pub fn write(ctx: &Ctx, device: &str) -> Result<()> {
    let device1 = format!("/dev/{device}1");
    let device2 = format!("/dev/{device}2");

    log("USB", "Unmounting USB stick");
    umount_if_exists(&device1);
    umount_if_exists(&device2);

    log("USB", "Writing ISO");
    sudo_system(
        ctx,
        &format!("dd if=$(ls result/iso/*.iso) of=/dev/{device} bs=1M status=progress"),
        "USB",
    )?;

    log("USB", "Unmounting");
    std::thread::sleep(std::time::Duration::from_secs(2));
    umount_if_exists(&device1);
    umount_if_exists(&device2);
    log("USB", "Done");
    Ok(())
}

fn umount_if_exists(device: &str) {
    if !Path::new(device).exists() {
        return;
    }
    let _ = std::process::Command::new("sh")
        .arg("-c")
        .arg(format!("{}umount {device}", sudo_prefix()))
        .status();
}
