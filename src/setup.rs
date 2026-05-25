#![allow(dead_code)]

//! Equivalent of lib/setup.rb. Only the helpers used by `nixx build` are
//! ported here for now; the full machine-bootstrap path comes with
//! `nixx setup`.

use anyhow::{bail, Context, Result};
use std::process::Command;

use crate::credentials::Credentials;
use crate::ssh::Ssh;
use crate::system::{log, sh_quote, sudo_capture, sudo_prefix, sudo_system, sudo_system_redacted};
use crate::{wallpaper, Ctx};

const ALL_CHANNELS: &[&str] = &["catppuccin", "nixos-hardware", "nixos"];
const CATPPUCCIN_CHAN: &str = "https://github.com/catppuccin/nix/archive/main.tar.gz";
const HARDWARE_CHAN: &str = "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz";
const NIXOS_CHAN: &str = "https://nixos.org/channels/nixos-25.11";
const HOME_DIR: &str = "/home/nixos";

pub struct SetupPaths {
    pub root: String,
    pub nixfiles_dir: String,
    pub configuration_nix: String,
    pub github_ssh_key: String,
}

impl SetupPaths {
    pub fn new(ctx: &Ctx, root: &str, module: &str) -> Self {
        let nixfiles_dir = format!("{root}data/code/nixfiles");
        let configuration_nix = format!("{nixfiles_dir}/hosts/{}/{}", ctx.machine, module);
        Self {
            root: root.into(),
            nixfiles_dir,
            configuration_nix,
            github_ssh_key: format!("{HOME_DIR}/github_ssh_key"),
        }
    }
}

pub fn show_config(ctx: &Ctx) -> Result<()> {
    log("CONF", "Show hardware configuration");
    let out = sudo_capture("nixos-generate-config --show-hardware-config", "CONF")?;
    let _ = ctx;
    print!("{out}");
    Ok(())
}

pub fn github_ssh_key(ctx: &Ctx, paths: &SetupPaths, creds: &Credentials) -> Result<()> {
    log("SSH", &format!("Write GitHub SSH key to {}", paths.github_ssh_key));
    let key = creds
        .get(&["ssh", "github", &ctx.machine, "ed25519"])
        .context("missing ssh.github.<machine>.ed25519 in credentials")?;
    let private = key.get("private").and_then(|v| v.as_str()).context("missing private key")?;
    let public = key.get("public").and_then(|v| v.as_str()).context("missing public key")?;
    if ctx.dryrun {
        log("SSH", &format!("(dryrun) would write {} and .pub", paths.github_ssh_key));
        return Ok(());
    }
    std::fs::write(&paths.github_ssh_key, format!("{private}\n"))?;
    std::fs::write(format!("{}.pub", paths.github_ssh_key), public)?;
    use std::os::unix::fs::PermissionsExt;
    std::fs::set_permissions(&paths.github_ssh_key, std::fs::Permissions::from_mode(0o600))?;
    Ok(())
}

pub fn clone(ctx: &Ctx, paths: &SetupPaths) -> Result<()> {
    let settings = crate::settings::Settings::load(&ctx.app_dir)?;
    log("CLONE", "Cloning nixfiles repo");
    let cmd = format!(
        "GIT_SSH_COMMAND='ssh -i {}' git clone {} {}",
        paths.github_ssh_key, settings.repo, paths.nixfiles_dir
    );
    sudo_system(ctx, &cmd, "CLONE")?;
    sudo_system(ctx, &format!("chown -R 1000:users {}", paths.nixfiles_dir), "CLONE")?;
    Ok(())
}

pub fn master_key(ctx: &Ctx, paths: &SetupPaths) -> Result<()> {
    let config_path = format!("{}/config", paths.nixfiles_dir);
    log("SSH", &format!("Write master key to {config_path}"));
    let src = ctx.app_dir.join("config/master.key");
    let dst = format!("{config_path}/master.key");
    if ctx.dryrun {
        log("SSH", &format!("(dryrun) would copy {} to {dst}", src.display()));
        return Ok(());
    }
    std::fs::copy(&src, &dst)
        .with_context(|| format!("copying {} to {dst}", src.display()))?;
    Ok(())
}

pub fn wallpaper_setup(ctx: &Ctx, paths: &SetupPaths) -> Result<()> {
    let wallpaper_dir = format!("{}data/pictures/wallpaper", paths.root);
    sudo_system(ctx, &format!("mkdir -p {wallpaper_dir}"), "WALLPAPER")?;
    sudo_system(ctx, &format!("chown 1000:users {wallpaper_dir}"), "WALLPAPER")?;
    if !ctx.dryrun {
        wallpaper::download(None, false, &paths.root)?;
    }
    Ok(())
}

pub fn install(ctx: &Ctx, paths: &SetupPaths, creds: &Credentials) -> Result<()> {
    let _hashpw = creds.with_hashed_password()?;
    log("INSTALL", "Installing NixOS");
    sudo_system(ctx, &format!("mkdir -p {}etc/nixos", paths.root), "INSTALL")?;
    sudo_system(
        ctx,
        &format!(
            "ln -fs {} {}etc/nixos/configuration.nix",
            paths.configuration_nix, paths.root
        ),
        "INSTALL",
    )?;
    sudo_system(ctx, "nixos-install --no-root-password", "INSTALL")?;
    log("REBOOT", "Rebooting...");
    sudo_system(ctx, &format!("chown 1000:users {}data", paths.root), "REBOOT")?;
    sudo_system(ctx, &format!("umount -l {}", paths.root), "REBOOT")?;
    sudo_system(ctx, "zpool export -a", "REBOOT")?;
    sudo_system(ctx, "reboot", "REBOOT")?;
    Ok(())
}

pub fn wifi_wpa_supplicant(ctx: &Ctx, creds: &Credentials, network: &str) -> Result<()> {
    if connected(ctx)? {
        log("NET", "Connected");
        return Ok(());
    }
    log("NET", "Disconnected. Establish WIFI connection");
    let net_key = format!("wifi_{network}");
    let net = creds
        .get(&[&net_key])
        .with_context(|| format!("no `{net_key}` block in credentials"))?;
    let ssid = net.get("ssid").and_then(|v| v.as_str()).context("missing wifi ssid")?;
    let psk = net
        .get("password")
        .and_then(|v| v.as_str())
        .context("missing wifi password")?;
    let cmd = format!(
        "{}sh -c {}",
        sudo_prefix(),
        sh_quote(&format!(
            "wpa_passphrase {} {} > /etc/wpa_supplicant.conf",
            sh_quote(ssid),
            sh_quote(psk),
        )),
    );
    sudo_system_redacted(ctx, &cmd, "NET", &[psk])?;
    let iface = std::process::Command::new("sh")
        .arg("-c")
        .arg("ls /sys/class/ieee80211/*/device/net/")
        .output()
        .context("listing wifi interfaces")?;
    let iface = String::from_utf8(iface.stdout)?.trim().to_owned();
    sudo_system(
        ctx,
        &format!("wpa_supplicant -B -i{iface} -c/etc/wpa_supplicant.conf"),
        "NET",
    )?;
    wait_for_connection(ctx)?;
    Ok(())
}

pub fn add_channels(ctx: &Ctx) -> Result<()> {
    log("CHANNELS", "Checking channels");
    let listing = sudo_capture("nix-channel --list", "CHANNELS")?;
    let known: Vec<&str> = listing.split_whitespace().collect();
    if ALL_CHANNELS.iter().all(|c| known.contains(c)) {
        log("CHANNELS", "Up-to-date");
        return Ok(());
    }
    log("CHANNELS", "Updating");
    sudo_system(ctx, &format!("nix-channel --add {CATPPUCCIN_CHAN} catppuccin"), "CHANNELS")?;
    sudo_system(ctx, &format!("nix-channel --add {HARDWARE_CHAN} nixos-hardware"), "CHANNELS")?;
    sudo_system(ctx, &format!("nix-channel --add {NIXOS_CHAN} nixos"), "CHANNELS")?;
    sudo_system(ctx, "nix-channel --update", "CHANNELS")?;
    Ok(())
}

pub fn all_ssh_keys(creds: &mut Credentials, machine: &str, overwrite: bool) -> Result<()> {
    log("SSH", "Write all SSH keys to SSH dir");
    let ssh = Ssh::new(overwrite);
    ssh.generate_all_keys(creds)?;

    let persisted_machine_dir = if std::path::Path::new("/data/machine").is_dir() {
        std::path::PathBuf::from("/data/machine")
    } else {
        std::path::PathBuf::from(std::env::var("HOME").context("HOME not set")?)
    };
    let ssh_dir = persisted_machine_dir.join("ssh");
    ssh.write_keys_to(creds, machine, &ssh_dir)?;
    Ok(())
}

pub fn wifi(ctx: &Ctx, creds: &Credentials, network: &str) -> Result<()> {
    if connected(ctx)? {
        log("NET", "Connected");
        return Ok(());
    }
    log("NET", "Disconnected. Establish WIFI connection");
    let net_key = format!("wifi_{network}");
    let net = creds
        .get(&[&net_key])
        .with_context(|| format!("no `{net_key}` block in credentials"))?;
    let ssid = net.get("ssid").and_then(|v| v.as_str()).context("missing wifi ssid")?;
    let psk = net
        .get("password")
        .and_then(|v| v.as_str())
        .context("missing wifi password")?;
    let cmd = format!(
        "nmcli device wifi connect {} password {} wifi-sec.key-mgmt wpa-psk",
        sh_quote(ssid),
        sh_quote(psk),
    );
    sudo_system_redacted(ctx, &cmd, "NET", &[psk])?;
    wait_for_connection(ctx)?;
    Ok(())
}

fn connected(ctx: &Ctx) -> Result<bool> {
    if ctx.dryrun {
        return Ok(true);
    }
    Ok(Command::new("sh")
        .arg("-c")
        .arg("ping -c 1 google.com > /dev/null 2>&1")
        .status()?
        .success())
}

fn wait_for_connection(ctx: &Ctx) -> Result<()> {
    use std::io::Write;
    print!("[NET       ] Waiting for connection...");
    std::io::stdout().flush().ok();
    while !connected(ctx)? {
        std::thread::sleep(std::time::Duration::from_secs(1));
        print!(".");
        std::io::stdout().flush().ok();
    }
    println!();
    log("NET", "Connected");
    Ok(())
}

/// Checks if the current machine is "ephemeral OS" (root wipes on boot).
pub fn ephemeral_os(machine: &str) -> bool {
    machine == "aramid"
}

/// Returns NIXOS_CONFIG=<path-to-host-module>.
pub fn configuration_nix_env(ctx: &Ctx) -> String {
    ctx.configuration_nix_env()
}

/// Wraps a build/switch/boot command with the trace flag and an optional
/// `nom` pipe when stdout is a tty.
pub fn nixos_rebuild_cmd(ctx: &Ctx, command: &str, trace: bool, nom: bool) -> String {
    let trace_flag = if trace { " --show-trace" } else { "" };
    let nom_pipe = if nom && std::io::IsTerminal::is_terminal(&std::io::stdout()) {
        " |& nom"
    } else {
        ""
    };
    format!("{} nixos-rebuild {command}{trace_flag}{nom_pipe}", configuration_nix_env(ctx))
}

/// Decides the nixos-rebuild subcommand based on flags.
pub fn rebuild_subcommand(dryrun: bool, switch: bool, boot: bool, upgrade: bool, clean: bool) -> &'static str {
    if dryrun {
        return "dry-build";
    }
    if boot {
        return "boot";
    }
    if switch || upgrade || clean {
        return "switch";
    }
    "build"
}

/// Returns Ok if this is reachable; error messages are unused for now but
/// kept consistent with the Ruby version's exit_with semantics.
pub fn ensure_runnable() -> Result<()> {
    if which("nixos-rebuild").is_none() {
        bail!("nixos-rebuild not found in PATH");
    }
    Ok(())
}

fn which(prog: &str) -> Option<std::path::PathBuf> {
    std::env::var_os("PATH")?.to_str()?.split(':').find_map(|p| {
        let candidate = std::path::Path::new(p).join(prog);
        candidate.is_file().then_some(candidate)
    })
}
