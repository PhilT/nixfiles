# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal NixOS configuration repository that manages multiple machines using a custom Rust-based tool called `nixx`. The repository contains NixOS configurations, machine-specific setups, and automation tools for system deployment and management.

## Architecture

### Core Structure
- **`src/`**: Rust source for the `nixx` CLI (Cargo project at the repo root)
- **`modules/`**: Shared NixOS modules
  - `scripts/`: Custom utility scripts (g-dirty, g-cd, move-window, note, etc.)
  - Individual modules for specific functionality (neovim.nix, firefox.nix, etc.)
- **`hosts/`**: Machine-specific configurations (aramid, spruce, minoo)
- **`bin/`**: Executable shell scripts
- **`config/`**: YAML configuration files for machines and settings
- **`dotfiles/`**: Configuration files for various applications
- **`neovim/`**: Neovim Lua configuration files
  - `init.lua`: Main Neovim initialization
  - `plugins/`: Plugin-specific configuration files

### Machine Configurations
The repository manages several machines:
- **spruce**: Desktop PC (14900K, RTX4090) - Primary development machine
- **aramid**: Laptop (X1 Carbon Gen 12) - Uses ephemeral OS
- **minoo**: File server (N100-based)
- **vellum**: Boox Note Max e-ink tablet

### Key Concepts
- **Ephemeral OS**: aramid wipes `/etc` on boot for security
- **ZFS**: Uses ZFS for storage with encryption and dataset management
- **Module System**: Hierarchical NixOS module system with machine-specific overrides

## Common Commands

### Building and Deploying
```bash
nixx build                    # Build NixOS configuration
nixx build -s                 # Build and switch to new configuration
nixx build -b                 # Build for next boot
nixx build -u                 # Upgrade channels and switch
nixx build --clean            # Run garbage collection before build
nixx build -m <machine>       # Build for specific machine
```

**minoo builds must run on minoo itself** — building/switching minoo from spruce (`nixx build -m minoo` on spruce) does not work. SSH to minoo and run the build there (`ssh minoo 'nixx build -s -m minoo'`). The nixfiles repo is available at `/data/code/nixfiles` on minoo.

### Machine Setup
```bash
nixx setup -m <machine>       # Install NixOS on new machine
nixx setup --show             # Show hardware configuration
nixx iso                      # Build NixOS installation ISO
nixx usb <device>             # Create bootable USB (e.g., nixx usb sda)
```

### SSH and Credentials
```bash
nixx credentials edit         # Edit encrypted credentials file
nixx credentials show         # Display credentials
nixx keys                     # Generate missing SSH keys
```

### Development Tools
```bash
nixx diff                     # Show differences between system generations
nixx option <option>          # Query NixOS configuration option
nixx sha <url>                # Fetch SHA256 for package URL
```

### Testing
```bash
nix-shell --run "cargo test"   # Run the Rust test suite
```

## Configuration Management

### Machine Configuration Files
- `config/machines.yml`: Defines partitioning and ZFS pool setup for each machine
- `config/settings.yml`: Contains repository settings and remote URLs

### NixOS Module Structure
- `modules/base.nix`: Core packages, including the `nixx` binary
- `modules/minimal.nix`: Minimal system configuration
- `modules/common.nix`: Common system settings
- `hosts/<machine>/`: Machine-specific configurations
  - `default.nix`: Full desktop configuration
  - `minimal.nix`: Minimal configuration for setup
  - `machine.nix`: Hardware-specific settings

### Key Modules
- `modules/development.nix`: Development tools and environments
- `modules/neovim.nix`: Neovim configuration with debugging support (loads configs from `neovim/`)
- `modules/sway/`: Sway window manager configuration
- `modules/firefox.nix`: Browser setup
- `modules/mail.nix`: Email setup (mbsync, notmuch, himalaya)
- `modules/unison/`: File synchronization configuration
- `modules/scripts/`: Custom utility scripts including:
  - `g-dirty.nix`: Check for dirty git repositories
  - `g-cd.nix`: Git repository navigation
  - `move-window.nix`: Sway window management
  - `note.nix`: Quick note-taking script
  - `sw-generation.nix`: System generation management
- `modules/nixx.nix`: `buildRustPackage` derivation for the `nixx` CLI

## Development Workflow

1. Make changes to NixOS configurations in `modules/` or `hosts/`
2. Test with `nixx build` (dry run by default)
3. Apply changes with `nixx build -s`
4. For new machines, use `nixx setup -m <machine>`

For changes to `nixx` itself: enter the dev shell (`nix-shell` or via direnv) and run `cargo build` / `cargo test`. The `modules/nixx.nix` derivation rebuilds the binary as part of the system.

## Important Notes

- SSH keys are managed automatically and stored in encrypted credentials
- ZFS encryption is used on most machines with automatic key management
- Some machines use ephemeral root filesystems that reset on boot
- VFIO GPU passthrough is configured for VMs on the spruce machine

## File Locations

- NixOS configurations: `/data/code/nixfiles/modules/` and `/data/code/nixfiles/hosts/`
- Rust source for nixx: `/data/code/nixfiles/src/`
- Persistent data: `/data/` (home directories, code, etc.)
- SSH keys: Generated and managed by nixx tool
- Credentials: Encrypted file managed via `nixx credentials`
