use anyhow::{bail, Context, Result};
use clap::{Args, Parser, Subcommand};
use std::path::PathBuf;
use std::process::Command;

mod credentials;
mod disks;
mod iso;
mod marshal;
mod settings;
mod setup;
mod ssh;
mod system;
mod usb;
mod wallpaper;
mod zfs;

#[derive(Parser)]
#[command(name = "nixx", version, about = "NixOS configuration tool")]
#[command(arg_required_else_help = true)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

/// Flags for commands that target a specific machine + module.
#[derive(Args)]
struct MachineOpts {
    /// Pick a base module from hosts/<machine>/. Defaults to default.nix
    #[arg(short = 'o', long)]
    module: Option<String>,

    /// Operate on a different machine (aramid/minoo/spruce)
    #[arg(short = 'm', long)]
    machine: Option<String>,
}

#[derive(Subcommand)]
enum Commands {
    /// Fetch a SHA256 for the given package URL
    Sha {
        url: String,
        /// Don't actually run the command; just log it
        #[arg(long)]
        dryrun: bool,
    },
    /// Output value of a config option (e.g. persistedHomeDir)
    Option {
        option: String,
        #[command(flatten)]
        machine_opts: MachineOpts,
        /// Don't actually run the command; just log it
        #[arg(long)]
        dryrun: bool,
    },
    /// Diff changes between latest & previous system generations
    Diff {
        /// Don't actually run the command; just log it
        #[arg(long)]
        dryrun: bool,
    },
    /// Download wallpaper from Wallhaven
    #[command(arg_required_else_help = true)]
    Wallpaper {
        #[command(subcommand)]
        command: WallpaperCmd,
    },
    /// Manage encrypted credentials
    #[command(arg_required_else_help = true)]
    Credentials {
        #[command(subcommand)]
        command: CredentialsCmd,
    },
    /// Generate any missing SSH keys and store them in the credentials file
    Keys {
        /// Overwrite existing keys when contents differ
        #[arg(long)]
        overwrite: bool,
    },
    /// Build a NixOS install ISO
    Iso {
        /// Don't actually run the build
        #[arg(long)]
        dryrun: bool,
    },
    /// Setup a new NixOS machine
    Setup {
        #[command(flatten)]
        machine_opts: MachineOpts,
        /// Show hardware configuration and exit
        #[arg(long)]
        show: bool,
        /// Install NixOS without formatting
        #[arg(long)]
        install_only: bool,
        /// Don't actually run mutating commands
        #[arg(long)]
        dryrun: bool,
        /// WIFI network to connect to (home/mobile)
        #[arg(long, default_value = "home")]
        wifi: String,
    },
    /// Create any missing ZFS datasets and mount them
    Datasets {
        #[command(flatten)]
        machine_opts: MachineOpts,
        #[arg(long)]
        dryrun: bool,
    },
    /// Write a built ISO to a USB device (e.g. `nixx usb sda`)
    Usb {
        device: String,
        /// Don't actually run the writes
        #[arg(long)]
        dryrun: bool,
    },
    /// Rebuild NixOS
    Build {
        #[command(flatten)]
        machine_opts: MachineOpts,
        /// Run nixos-rebuild dry-build instead of build
        #[arg(long)]
        dryrun: bool,
        /// Switch to the new machine config
        #[arg(short = 's', long)]
        switch: bool,
        /// Switch to the new config on next boot
        #[arg(short = 'b', long)]
        boot: bool,
        /// Upgrade the channel and switch
        #[arg(short = 'u', long)]
        upgrade: bool,
        /// Run nix-collect-garbage -d before build
        #[arg(long)]
        clean: bool,
        /// Show trace
        #[arg(short = 't', long)]
        trace: bool,
        /// Overwrite existing SSH keys
        #[arg(long)]
        overwrite: bool,
        /// Disable piping nixos-rebuild output through nom
        #[arg(long)]
        no_nom: bool,
        /// WIFI network to connect to (home/mobile)
        #[arg(long, default_value = "home")]
        wifi: String,
    },
}

#[derive(Subcommand)]
enum CredentialsCmd {
    /// Decrypt and print a single credential by dot-separated key (e.g. wifi_mobile.ssid)
    Show {
        /// Dot-separated path into the credentials YAML
        key: String,
    },
    /// Rotate a credential in place. Works for SSH keypairs (ed25519/ecdsa/rsa)
    /// and for scalars with a sibling `<name>_format` entry (e.g. alphanumeric-10).
    Rotate {
        /// Dot-separated path to the value (or ssh keypair) to rotate
        key: String,
    },
    /// Open credentials in $EDITOR, validate YAML, and re-encrypt
    Edit,
}

#[derive(Subcommand)]
enum WallpaperCmd {
    /// Download wallpaper from Wallhaven. SCREEN can be 'left' or 'right'
    Download {
        screen: Option<String>,
        /// Apply wallpaper to sway after downloading
        #[arg(long)]
        apply: bool,
        /// Mount point prefix for the save directory
        #[arg(long, default_value = "")]
        mnt: String,
    },
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    let app_dir = find_app_dir()?;

    match cli.command {
        Commands::Sha { url, dryrun } => {
            let ctx = Ctx::new(app_dir, None, None, dryrun)?;
            cmd_sha(&ctx, &url)
        }
        Commands::Option { option, machine_opts, dryrun } => {
            let ctx = Ctx::new(app_dir, machine_opts.machine, machine_opts.module, dryrun)?;
            cmd_option(&ctx, &option)
        }
        Commands::Diff { dryrun } => {
            let ctx = Ctx::new(app_dir, None, None, dryrun)?;
            cmd_diff(&ctx)
        }
        Commands::Wallpaper { command } => match command {
            WallpaperCmd::Download { screen, apply, mnt } => {
                wallpaper::download(screen.as_deref(), apply, &mnt)
            }
        },
        Commands::Credentials { command } => match command {
            CredentialsCmd::Show { key } => credentials::cmd_show(&app_dir, &key),
            CredentialsCmd::Rotate { key } => credentials::cmd_rotate(&app_dir, &key),
            CredentialsCmd::Edit => credentials::cmd_edit(&app_dir),
        },
        Commands::Keys { overwrite } => {
            let mut creds = credentials::Credentials::load(&app_dir)?;
            ssh::Ssh::new(overwrite).generate_all_keys(&mut creds)
        }
        Commands::Setup { machine_opts, show, install_only, dryrun, wifi } => {
            let module = machine_opts.module.unwrap_or_else(|| "minimal.nix".into());
            let ctx = Ctx::new(app_dir, machine_opts.machine, Some(module.clone()), dryrun)?;
            cmd_setup(&ctx, &module, show, install_only, &wifi)
        }
        Commands::Datasets { machine_opts, dryrun } => {
            let ctx = Ctx::new(app_dir, machine_opts.machine, machine_opts.module, dryrun)?;
            let creds = credentials::Credentials::load(&ctx.app_dir)?;
            let disks = disks::Disks::load(&ctx.app_dir, &ctx.machine, false, "/", &creds)?;
            disks.partition(&ctx)
        }
        Commands::Usb { device, dryrun } => {
            let ctx = Ctx::new(app_dir, None, None, dryrun)?;
            usb::write(&ctx, &device)
        }
        Commands::Iso { dryrun } => {
            let ctx = Ctx::new(app_dir.clone(), None, None, dryrun)?;
            let creds = credentials::Credentials::load(&app_dir)?;
            let _guard = ssh::PublicKeysGuard::create(&creds)?;
            iso::build(&ctx)
        }
        Commands::Build {
            machine_opts,
            dryrun,
            switch,
            boot,
            upgrade,
            clean,
            trace,
            overwrite,
            no_nom,
            wifi,
        } => {
            let ctx = Ctx::new(app_dir.clone(), machine_opts.machine, machine_opts.module, dryrun)?;
            cmd_build(&ctx, switch, boot, upgrade, clean, trace, overwrite, !no_nom, &wifi)
        }
    }
}

fn cmd_setup(ctx: &Ctx, module: &str, show: bool, install_only: bool, wifi: &str) -> Result<()> {
    let creds = credentials::Credentials::load(&ctx.app_dir)?;
    let paths = setup::SetupPaths::new(ctx, "/mnt/", module);

    if show {
        return setup::show_config(ctx);
    }

    if install_only {
        setup::github_ssh_key(ctx, &paths, &creds)?;
        return setup::install(ctx, &paths, &creds);
    }

    setup::github_ssh_key(ctx, &paths, &creds)?;
    setup::wifi_wpa_supplicant(ctx, &creds, wifi)?;
    let disks = disks::Disks::load(&ctx.app_dir, &ctx.machine, true, &paths.root, &creds)?;
    disks.partition(ctx)?;
    setup::clone(ctx, &paths)?;
    setup::master_key(ctx, &paths)?;
    setup::add_channels(ctx)?;
    setup::wallpaper_setup(ctx, &paths)?;
    setup::install(ctx, &paths, &creds)
}

fn cmd_build(
    ctx: &Ctx,
    switch: bool,
    boot: bool,
    upgrade: bool,
    clean: bool,
    trace: bool,
    overwrite: bool,
    nom: bool,
    wifi: &str,
) -> Result<()> {
    let command = setup::rebuild_subcommand(ctx.dryrun, switch, boot, upgrade, clean);
    let mut creds = credentials::Credentials::load(&ctx.app_dir)?;
    let disks_creds = credentials::Credentials::load(&ctx.app_dir)?;
    let disks = disks::Disks::load(&ctx.app_dir, &ctx.machine, false, "/", &disks_creds)?;

    setup::add_channels(ctx)?;
    setup::all_ssh_keys(&mut creds, &ctx.machine, overwrite)?;
    setup::wifi(ctx, &creds, wifi)?;

    if disks.more_than_one() {
        zfs::switch_to_key_based_encryption()?;
    }

    system::log(command, &ctx.machine);
    if clean {
        system::sudo_system(ctx, "nix-collect-garbage -d", "BUILD")?;
    }
    if upgrade {
        system::sudo_system(ctx, "nix-channel --update", "BUILD")?;
    }

    let _pubkeys = ssh::PublicKeysGuard::create(&creds)?;
    let _hashpw = creds.with_hashed_password()?;
    let cmd = setup::nixos_rebuild_cmd(ctx, command, trace, nom);
    system::sudo_system(ctx, &cmd, "BUILD")
}

/// Runtime context for shell-out commands.
pub struct Ctx {
    pub app_dir: PathBuf,
    pub machine: String,
    pub module: String,
    pub dryrun: bool,
}

impl Ctx {
    fn new(app_dir: PathBuf, machine: Option<String>, module: Option<String>, dryrun: bool) -> Result<Self> {
        let machine = match machine {
            Some(m) => m,
            None => hostname()?,
        };
        let module = module.unwrap_or_else(|| "default.nix".into());
        Ok(Self { app_dir, machine, module, dryrun })
    }

    pub fn configuration_nix_env(&self) -> String {
        let path = self.app_dir.join("hosts").join(&self.machine).join(&self.module);
        format!("NIXOS_CONFIG={}", path.display())
    }
}

/// Walk up from CWD looking for `config/settings.yml` — the repo root marker.
/// Falls back to `$SRC` if CWD is outside the repo.
fn find_app_dir() -> Result<PathBuf> {
    let mut dir = std::env::current_dir().context("getting current directory")?;
    loop {
        if dir.join("config/settings.yml").is_file() {
            return Ok(dir);
        }
        if !dir.pop() {
            break;
        }
    }
    if let Ok(src) = std::env::var("SRC") {
        let p = PathBuf::from(src);
        if p.join("config/settings.yml").is_file() {
            return Ok(p);
        }
    }
    bail!("could not locate repo root (no config/settings.yml found walking up from CWD or via $SRC)");
}

fn hostname() -> Result<String> {
    let out = Command::new("hostname").output().context("running hostname")?;
    Ok(String::from_utf8(out.stdout)?.trim().to_string())
}

fn cmd_sha(ctx: &Ctx, url: &str) -> Result<()> {
    system::run_system(ctx, &format!("nix-prefetch-url {url}"), "SHA")
}

fn cmd_option(ctx: &Ctx, option: &str) -> Result<()> {
    let cmd = format!("{} nixos-option {option}", ctx.configuration_nix_env());
    system::run_capture(ctx, &cmd, "OPTION", true)
}

fn cmd_diff(ctx: &Ctx) -> Result<()> {
    let cmd = "nvd diff $(ls -d1v /nix/var/nix/profiles/system-*-link|tail -n 2)";
    system::run_capture(ctx, cmd, "DIFF", true)
}
