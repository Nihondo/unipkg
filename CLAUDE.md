# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains `unipkg`, a unified command-line tool for managing packages across multiple package managers. The tool provides a consistent interface to list, get information, delete, and update packages from **19 different package management systems** on macOS and other Unix-like systems. It supports **version display functionality** across all supported package managers.

## Core Script Architecture

`unipkg` follows a modular function-based architecture:

- **Main execution flow**: Option parsing → Package manager detection → Data collection → Output formatting
- **Package manager handlers**: Individual functions (`get_*_packages()`) for each supported package manager
- **Output formatters**: Separate functions for table, JSON, and CSV output formats
- **Error handling**: Consistent warning/error messaging with optional color output

The script uses bash's `set -euo pipefail` for strict error handling and employs a data collection pattern where each package manager function outputs CSV-formatted data that gets aggregated and processed. It supports multiple operation modes: listing (`default`), package information (`-i`), deletion (`-d`), update (`-u/--update`), and **version display (`-v/--with-version`)** with safety features including confirmation prompts and dry-run capability.

## Supported Package Managers

### Application Package Managers (7)
- **brew**: Homebrew (macOS) - uses `brew list --formula` (with `--versions` for version display)
- **npm**: Node.js packages - uses `npm list -g --depth=0` (parseable or text format with version parsing)
- **perl**: Perl modules - uses `ExtUtils::Installed` (with version retrieval via `$inst->version()`)
- **pip3**: Python packages - uses `pip3 list --format=freeze` (package==version format)
- **gem**: Ruby gems - uses `gem list` (with/without `--no-versions`, handles `default:` prefix)
- **cargo**: Rust packages - uses `cargo install --list` (package vX.X.X: format)
- **go**: Go modules - searches `$GOPATH/pkg/mod` or `$HOME/go/pkg/mod` (package@version format)

### System Package Managers (5)
- **dnf**: DNF (Fedora/RHEL 8+) - uses `dnf list installed` (with version from format parsing)
- **yum**: YUM (RHEL/CentOS) - uses `yum list installed` (with version from format parsing)
- **apt**: APT (Debian/Ubuntu) - uses `apt list --installed` (with version from format parsing)
- **dpkg**: DPKG (Debian/Ubuntu) - uses `dpkg -l` (with version from column 3)
- **rpm**: RPM (Red Hat系) - uses `rpm -qa --queryformat '%{NAME} %{VERSION}-%{RELEASE}'` for version display

### Version Managers (9)
- **nvm**: Node Version Manager - checks `~/.nvm/versions/node` (displays as "Node.js" with versions)
- **rbenv**: Ruby Version Manager - uses `rbenv versions --bare` or checks `~/.rbenv/versions` (displays as "Ruby" with versions)
- **pyenv**: Python Version Manager - uses `pyenv versions --bare` or checks `~/.pyenv/versions` (displays as "Python" with versions)
- **nodenv**: Node Version Manager (alternative) - uses `nodenv versions --bare` or checks `~/.nodenv/versions` (displays as "Node.js" with versions)
- **tfenv**: Terraform Version Manager - uses `tfenv list` or checks `~/.tfenv/versions` (displays as "Terraform" with versions)
- **jenv**: Java Version Manager - uses `jenv versions --bare` or checks `~/.jenv/versions` (displays as "Java" with versions)
- **asdf**: Universal Version Manager - uses `asdf plugin list` and `asdf list` (shows plugins as packages with versions)
- **gvm**: Go Version Manager - checks `~/.gvm/gos` (displays as "Go" with versions)
- **rustup**: Rust toolchain installer - uses `rustup toolchain list` (displays as "Rust" with toolchain versions)

## Common Commands

### Execute the script
```bash
# Make executable (if needed)
chmod +x unipkg

# List all packages from all managers
./unipkg

# Show package counts only
./unipkg -c

# List specific package managers
./unipkg brew npm pip3

# List system package managers only
./unipkg dnf apt rpm

# List version managers only
./unipkg nvm pyenv rbenv asdf

# Display packages with version information
./unipkg -v

# Display specific managers with versions
./unipkg brew npm -v

# Output in JSON format
./unipkg -f json

# Output with versions in JSON format
./unipkg -v -f json

# Show package information
./unipkg -i git

# Show package info from specific manager
./unipkg -i express npm

# Delete package with confirmation
./unipkg -d oldpackage

# Dry run delete to see what would happen
./unipkg -d package --dry-run

# Force delete without confirmation
./unipkg -d package --force

# Update all packages
./unipkg -u

# Update specific package
./unipkg -u somepackage

# Dry run update to see what would happen
./unipkg -u --dry-run

# Output to file
./unipkg -o packages.csv -f csv

# Display help
./unipkg --help
```

### Testing the script
```bash
# Test individual package manager functions by examining the script
# No formal test suite exists - manual verification recommended

# Test count mode for quick verification
./unipkg -c

# Test specific managers that are known to be installed
./unipkg brew
```

## Development Notes

- Package manager detection uses `command -v` for availability checking
- Each package manager function handles both count-only and full listing modes (with version support)
- CSV is used as the internal data format before final output conversion (supports Manager,Package,Version format)
- Version parsing is implemented individually for each package manager due to varying output formats
- Color output can be disabled with `--no-color` flag
- Error messages are sent to stderr while data goes to stdout
- Version display adds significant command execution time due to additional parsing requirements