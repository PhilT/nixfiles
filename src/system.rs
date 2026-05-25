//! Equivalent of lib/system.rb: logging + shell-out helpers.
//!
//! Two run flavours, matching Ruby's distinction:
//! - `run_capture`: stdout/stderr captured (default for most commands).
//! - `run_system`: stdout/stderr inherited from parent — for `nixos-rebuild`
//!   and similar commands whose live progress output we want to see.

use anyhow::{bail, Context, Result};
use std::process::{Command, Stdio};
use std::sync::OnceLock;

use crate::Ctx;

/// Returns "sudo " if the current user is not root, otherwise "". Cached.
pub fn sudo_prefix() -> &'static str {
    static PREFIX: OnceLock<&'static str> = OnceLock::new();
    PREFIX.get_or_init(|| {
        let out = Command::new("whoami").output().ok();
        match out {
            Some(o) if String::from_utf8_lossy(&o.stdout).trim() == "root" => "",
            _ => "sudo ",
        }
    })
}

/// Run a command via sudo (if needed) and capture stdout — useful for
/// commands that read state, like `nix-channel --list`.
pub fn sudo_capture(cmd: &str, section: &str) -> Result<String> {
    let full = format!("{}{cmd}", sudo_prefix());
    log(section, &full);
    let out = Command::new("sh")
        .arg("-c")
        .arg(&full)
        .stdin(Stdio::null())
        .output()
        .context("spawning sudo command")?;
    if !out.status.success() {
        bail!(
            "sudo command failed (exit {:?}): {full}\nstderr: {}",
            out.status.code(),
            String::from_utf8_lossy(&out.stderr).trim()
        );
    }
    Ok(String::from_utf8(out.stdout)?)
}

/// Run a command via sudo (if needed), inheriting stdio. Use for commands
/// whose progress output should reach the user (nixos-rebuild, etc).
pub fn sudo_system(ctx: &Ctx, cmd: &str, section: &str) -> Result<()> {
    sudo_system_redacted(ctx, cmd, section, &[])
}

/// Like `sudo_system`, but replaces each string in `secrets` with `<REDACTED>`
/// in the logged command and in any error message. The command itself is
/// still executed verbatim.
pub fn sudo_system_redacted(
    ctx: &Ctx,
    cmd: &str,
    section: &str,
    secrets: &[&str],
) -> Result<()> {
    let full = format!("{}{cmd}", sudo_prefix());
    let display = redact(&full, secrets);
    log(section, &display);
    if ctx.dryrun {
        return Ok(());
    }
    let status = Command::new("sh").arg("-c").arg(&full).status()?;
    if !status.success() {
        bail!("sudo command failed (exit {:?}): {display}", status.code());
    }
    Ok(())
}

fn redact(s: &str, secrets: &[&str]) -> String {
    let mut out = s.to_owned();
    for secret in secrets {
        if !secret.is_empty() {
            out = out.replace(secret, "<REDACTED>");
        }
    }
    out
}

/// Quote `s` for safe inclusion in a `sh -c` command line, using single quotes.
pub fn sh_quote(s: &str) -> String {
    format!("'{}'", s.replace('\'', "'\\''"))
}

/// Prompt the user, blocking until they hit ENTER. Skipped in dryrun.
pub fn wait_for_input(ctx: &Ctx, prompt: &str) -> Result<()> {
    if ctx.dryrun {
        log("WAIT", prompt);
        return Ok(());
    }
    use std::io::{BufRead, Write};
    print!("{prompt}: ");
    std::io::stdout().flush().ok();
    let mut s = String::new();
    std::io::stdin().lock().read_line(&mut s).ok();
    Ok(())
}

pub fn log(section: &str, message: &str) {
    let section = format!("[{:<10}] ", section.to_uppercase());
    println!("{section}{message}");
}

pub fn run_capture(ctx: &Ctx, cmd: &str, section: &str, show_stdout: bool) -> Result<()> {
    log(section, cmd);
    if ctx.dryrun {
        return Ok(());
    }
    let out = Command::new("sh")
        .arg("-c")
        .arg(cmd)
        .stdin(Stdio::null())
        .output()?;
    if !out.status.success() {
        log("FAIL", cmd);
        eprintln!("Exit code: {:?}", out.status.code());
        if !out.stdout.is_empty() {
            eprintln!("Result: {}", String::from_utf8_lossy(&out.stdout));
        }
        if !out.stderr.is_empty() {
            eprintln!("Errors: {}", String::from_utf8_lossy(&out.stderr));
        }
        bail!("command failed: {cmd}");
    }
    if show_stdout {
        print!("{}", String::from_utf8_lossy(&out.stdout));
    }
    Ok(())
}

/// Shell out without logging or capturing — for fire-and-forget calls
/// (e.g. swaymsg) where the caller doesn't care about the output.
pub fn run_capture_quiet(cmd: &str) -> Result<()> {
    let status = Command::new("sh").arg("-c").arg(cmd).status()?;
    if !status.success() {
        bail!("command failed (exit {:?}): {cmd}", status.code());
    }
    Ok(())
}

pub fn run_system(ctx: &Ctx, cmd: &str, section: &str) -> Result<()> {
    log(section, cmd);
    if ctx.dryrun {
        return Ok(());
    }
    let status = Command::new("sh").arg("-c").arg(cmd).status()?;
    if !status.success() {
        bail!("command failed (exit {:?}): {cmd}", status.code());
    }
    Ok(())
}
