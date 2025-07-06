# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains `unipkg`, a unified command-line tool for managing packages across multiple package managers. The tool provides a consistent interface to list, get information, delete, and update packages from **19 different package management systems** on macOS and other Unix-like systems. It supports **version display functionality** and **latest version comparison with status indication** across supported package managers.

## Modular Architecture

`unipkg` follows a **modular architecture** where package manager functionality is separated into independent modules:

### Core Components
- **`unipkg`**: Main executable script that orchestrates package manager operations
- **`manager/common.sh`**: Shared utility functions used by all package manager modules
- **`manager/application/`**: Application package manager modules (8 modules)
- **`manager/system/`**: System package manager modules (5 modules)  
- **`manager/version/`**: Version manager modules (9 modules)

### Module Structure
Each package manager module (`manager/*/name.sh`) implements four standard functions:
- **`get_*_packages()`**: Lists packages with support for count-only, version display, and latest version comparison
- **`get_*_info()`**: Retrieves detailed package information
- **`delete_*_package()`**: Removes packages with confirmation prompts and dry-run support
- **`update_*_package()`**: Updates packages with confirmation and dry-run capabilities

### Key Architectural Patterns
- **Dynamic module loading**: Modules are loaded on-demand using `load_manager_module()`
- **CSV-based data flow**: Internal data format is CSV that gets converted to table/JSON/CSV output
- **Common utility functions**: Shared functions in `common.sh` for mode detection, messaging, and formatting
- **Status indication**: New version mode (`-nv`) shows Latest/Outdated status with color coding

## Latest Version Comparison Feature

The following package managers support the `-nv/--new-version` option with status indication:

### Fully Implemented with Status
- **brew**: Uses `brew outdated --verbose` for efficient bulk update detection
- **npm**: Uses `npm view <package> version` for individual package latest version lookup
- **gem**: Uses `gem list <package> --remote --exact` for remote version checking
- **pip3**: Uses local version info (limited functionality)
- **dnf**: Uses `dnf list updates` for efficient bulk update detection

### Status Display
- **Latest** (green): Current version is up-to-date
- **Outdated** (red): Update available
- Rich table display with color coding when `--no-color` is not specified

## Common Commands

### Basic Operations
```bash
# Make executable (if needed)
chmod +x unipkg

# List all packages from all managers
./unipkg

# Show package counts only
./unipkg -c

# List specific package managers
./unipkg brew npm pip3

# Display packages with version information
./unipkg -v

# Display with latest version comparison and status
./unipkg -nv

# Output in different formats
./unipkg -f json
./unipkg -v -f csv -o packages.csv
```

### Package Management
```bash
# Show package information
./unipkg -i git

# Delete package with confirmation
./unipkg -d oldpackage

# Update packages
./unipkg -u

# Dry run operations
./unipkg -d package --dry-run
./unipkg -u --dry-run
```

### Testing
```bash
# Quick verification of functionality
./unipkg -c

# Test specific managers
./unipkg brew npm -v

# Test latest version functionality
./unipkg brew -nv
```

## Development Notes

### Adding New Package Managers
1. Create new module in appropriate `manager/` subdirectory
2. Implement the four standard functions (`get_*`, `get_*_info`, `delete_*`, `update_*`)
3. Source `../common.sh` and use common utility functions
4. Add manager to `SUPPORTED_MANAGERS` array in main script
5. Add case entry in `load_manager_module()` function

### Module Implementation Requirements
- Use `command_exists` to check if package manager is available
- Handle count-only mode with `is_count_only()`
- Support version display with `is_version_mode()`
- Implement latest version comparison with `is_new_version_mode()` if applicable
- Use `output_csv` for consistent data formatting
- Include error handling with common message functions

### Path Resolution
- Modules use `$(command -v command_name)` to get full paths for package manager executables
- This prevents issues with PATH resolution in different execution contexts
- Critical for brew and other managers that may not be in standard PATH

### Output Format Consistency
- CSV format: `Manager,Package[,Version[,Latest_Version[,Status]]]`
- Status field only present in new version mode (`-nv`)
- Rich table formatting includes color coding for status indication
- JSON and CSV outputs preserve all data fields including status

## Compatibility Notes

- Compatible with bash 3.2.57+ (uses arrays instead of associative arrays for older bash support)
- Requires `command -v` for package manager detection
- Color output uses ANSI escape codes (disable with `--no-color`)
- Each package manager must be individually installed and available in PATH