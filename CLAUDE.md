# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal NixOS configuration repository that manages multiple machines using a custom Ruby-based tool called `nixx`. The repository contains NixOS configurations, machine-specific setups, and automation tools for system deployment and management.

## Architecture

### Core Structure
- **`src/`**: Contains all NixOS configuration modules
  - `machines/`: Machine-specific configurations (aramid, spruce, seedling, minoo, vellum)
  - `scripts/`: Custom utility scripts (g-dirty, g-cd, move-window, note, etc.)
  - Individual modules for specific functionality (neovim.nix, firefox.nix, etc.)
- **`lib/`**: Ruby library files for the nixx tool
- **`bin/`**: Executable scripts and VM management tools
- **`config/`**: YAML configuration files for machines and settings
- **`dotfiles/`**: Configuration files for various applications
- **`neovim/`**: Neovim Lua configuration files
  - `init.lua`: Main Neovim initialization
  - `plugins/`: Plugin-specific configuration files

### Machine Configurations
The repository manages several machines:
- **spruce**: Desktop PC (14900K, RTX4090) - Primary development machine
- **aramid**: Laptop (X1 Carbon Gen 12) - Uses ephemeral OS
- **seedling**: Development VM running on spruce
- **minoo**: File server (N100-based)
- **vellum**: Boox Note Max e-ink tablet

### Key Concepts
- **Ephemeral OS**: Some machines (aramid, seedling) wipe `/etc` on boot for security
- **ZFS**: Uses ZFS for storage with encryption and dataset management
- **Module System**: Hierarchical NixOS module system with machine-specific overrides

## Common Commands

### Building and Deploying
```bash
lib/nixx build                    # Build NixOS configuration
lib/nixx build -s                 # Build and switch to new configuration
lib/nixx build -b                 # Build for next boot
lib/nixx build -u                 # Upgrade channels and switch
lib/nixx build --clean            # Run garbage collection before build
lib/nixx build -m <machine>       # Build for specific machine
```

### Machine Setup
```bash
lib/nixx setup -m <machine>       # Install NixOS on new machine
lib/nixx setup --show             # Show hardware configuration
lib/nixx iso                      # Build NixOS installation ISO
lib/nixx usb <device>             # Create bootable USB (e.g., nixx usb sda)
```

### SSH and Credentials
```bash
lib/nixx credentials edit         # Edit encrypted credentials file
lib/nixx credentials show         # Display credentials
lib/nixx keys                     # Generate missing SSH keys
```

### Development Tools
```bash
lib/nixx diff                     # Show differences between system generations
lib/nixx option <option>          # Query NixOS configuration option
lib/nixx sha <url>                # Fetch SHA256 for package URL
```

### VM Management
```bash
bin/vm <machine> install [-f]  # Start VM with install ISO
bin/vm <machine> display       # Start VM with display
bin/vm <machine>               # Start VM with VFIO passthrough
```

### Testing
```bash
rake test                      # Run Ruby test suite
```

## Configuration Management

### Machine Configuration Files
- `config/machines.yml`: Defines partitioning and ZFS pool setup for each machine
- `config/settings.yml`: Contains repository settings and remote URLs

### NixOS Module Structure
- `src/base.nix`: Core packages and Ruby environment for nixx tool
- `src/minimal.nix`: Minimal system configuration
- `src/common.nix`: Common system settings
- `src/machines/<machine>/`: Machine-specific configurations
  - `default.nix`: Full desktop configuration
  - `minimal.nix`: Minimal configuration for setup
  - `machine.nix`: Hardware-specific settings

### Key Modules
- `src/development.nix`: Development tools and environments
- `src/neovim.nix`: Neovim configuration with debugging support (loads configs from `neovim/`)
- `src/sway/`: Sway window manager configuration
- `src/firefox.nix` & `src/thunderbird.nix`: Browser and email setup
- `src/unison/`: File synchronization configuration
- `src/scripts/`: Custom utility scripts including:
  - `g-dirty.nix`: Check for dirty git repositories
  - `g-cd.nix`: Git repository navigation
  - `move-window.nix`: Sway window management
  - `note.nix`: Quick note-taking script
  - `sw-generation.nix`: System generation management

## Development Workflow

1. Make changes to NixOS configurations in `src/`
2. Test with `nixx build` (dry run by default)
3. Apply changes with `nixx build -s`
4. For new machines, use `nixx setup -m <machine>`

## Important Notes

- The nixx tool requires Ruby 3.4 and specific gems (thor, activesupport)
- SSH keys are managed automatically and stored in encrypted credentials
- ZFS encryption is used on most machines with automatic key management
- Some machines use ephemeral root filesystems that reset on boot
- VFIO GPU passthrough is configured for VMs on the spruce machine

## File Locations

- NixOS configurations: `/data/code/nixfiles/src/`
- Persistent data: `/data/` (home directories, code, etc.)
- SSH keys: Generated and managed by nixx tool
- Credentials: Encrypted file managed via `nixx credentials`