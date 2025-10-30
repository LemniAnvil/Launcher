<div align="center">

<img src="Launcher/Launcher/Resources/Assets.xcassets/AppIcon.appiconset/mac256.png" alt="Launcher Icon" width="128" height="128">

# Minecraft Launcher

**A modern Minecraft launcher built with Swift for macOS**

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS-blue.svg)](https://www.apple.com/macos)
[![License](https://img.shields.io/badge/License-AGPL--3.0-blue.svg)](LICENSE)

English | [简体中文](README.zh-CN.md)

</div>

---

## Table of Contents

- [Features](#-features)
- [Screenshots](#-screenshots)
- [Quick Start](#-quick-start)
  - [Requirements](#requirements)
  - [Installation](#installation)
  - [Running the Project](#running-the-project)
- [Project Structure](#-project-structure)
- [Usage Guide](#-usage-guide)
  - [Test Window Features](#test-window-features)
  - [Version Selection](#version-selection)
- [Technical Stack](#-technical-stack)
- [Architecture](#-architecture)
- [Download Information](#-download-information)
- [Development](#-development)
  - [Completed Features](#-completed-features)
  - [Planned Features](#-planned-features)
- [Documentation](#-documentation)
- [Contributing](#-contributing)
- [Troubleshooting](#-troubleshooting)
- [License](#-license)

---

## Features

### Core Functionality
- **Version Management** - Fetch, parse, and cache Minecraft versions from official API
- **Download System** - Multi-threaded concurrent downloads with SHA1 verification
- **Proxy Support** - HTTP/HTTPS/SOCKS5 proxy configuration for network access
- **Version Filtering** - Filter by release, snapshot, beta, and alpha versions
- **Installation Check** - Automatically detect installed versions
- **Internationalization** - Full support for English and Simplified Chinese

### Technical Features
- Version inheritance handling (supports Forge/Fabric)
- Platform compatibility check (macOS optimized)
- Smart file verification (auto-skip existing files)
- Real-time progress tracking with download speed
- Swift Concurrency with async/await
- Comprehensive logging system

---

## Screenshots

### Main Window
The main window provides a clean interface to access the test functionality.

### Test Window
The test window offers comprehensive testing capabilities with:
- Version list with visual table view
- Real-time download progress tracking
- Detailed logging output
- Proxy configuration panel
- Version filtering options

---

## Quick Start

### Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/Launcher.git
cd Launcher
```

2. Open the project in Xcode:
```bash
open Launcher/Launcher.xcodeproj
```

### Running the Project

1. Select the `Launcher` scheme in Xcode
2. Press `⌘+R` to build and run
3. Click "Open Test Window" button in the main window
4. Test various features in the test window

---

## Project Structure

```
Launcher/
├── Launcher/
│   ├── Models/                 # Data models
│   │   ├── Version.swift       # Minecraft version data structures
│   │   ├── Library.swift       # Library dependency models
│   │   ├── Asset.swift         # Game asset models
│   │   └── Download.swift      # Download task models
│   ├── Managers/               # Manager classes
│   │   ├── VersionManager.swift    # Version management
│   │   ├── DownloadManager.swift   # Download management
│   │   └── ProxyManager.swift      # Proxy configuration
│   ├── Utils/                  # Utility classes
│   │   ├── Logger.swift        # Logging system
│   │   ├── FileUtils.swift     # File operations
│   │   └── VersionManifestParser.swift
│   ├── Application/            # Application layer
│   │   └── Localized.swift     # Localization strings
│   ├── Views/                  # User interface
│   │   ├── ViewController.swift
│   │   ├── TestWindowController.swift
│   │   └── TestViewController.swift
│   └── Resources/              # Resources
│       ├── Assets.xcassets/    # App icons and images
│       └── Localizable.xcstrings   # Localization catalog
├── LauncherTests/              # Unit tests
└── LauncherUITests/            # UI tests
```

---

## Usage Guide

### Test Window Features

The test window provides 5 main testing functions:

1. **Refresh Version List** - Fetch all available versions from Mojang's API
   - Displays latest release and snapshot versions
   - Shows version type statistics
   - Caches version data locally

2. **Get Version Details** - Parse detailed information for a selected version
   - Main class information
   - Java version requirements
   - Library dependencies
   - Asset index details

3. **Download Test File** - Test download functionality
   - Downloads version manifest
   - Verifies file integrity
   - Reports download speed

4. **Check Installed Versions** - Scan for locally installed versions
   - Lists all installed versions
   - Shows file sizes
   - Displays installation paths

5. **Download Full Version** - Download complete game files
   - Downloads game core (JAR file)
   - Downloads all required libraries
   - Downloads game assets
   - Shows real-time progress

### Version Selection

- **Visual Table View**: Browse versions in an organized table
- **Version Filtering**: Filter by type using checkboxes
  - 🟢 Release - Stable versions
  - 🟡 Snapshot - Development snapshots
  - 🔵 Beta - Legacy beta versions
  - 🟣 Alpha - Legacy alpha versions
- **Installation Status**: Shows which versions are already installed
- **Smart Selection**: Automatically selects latest release version
- **Double-Click**: Double-click a version to start downloading

### Proxy Configuration

Configure network proxy to access Mojang services:

1. Enable proxy by checking "Enable Proxy"
2. Select proxy type (HTTP/HTTPS/SOCKS5)
3. Enter proxy host and port
4. Click "Apply Proxy" to activate
5. Use "Test Proxy" to verify connection

---

## Technical Stack

- **Language**: Swift 5.9+
- **UI Framework**: AppKit (Native macOS)
- **Concurrency**: Swift Concurrency (async/await)
- **Cryptography**: CryptoKit (SHA1 verification)
- **Networking**: URLSession with custom configuration
- **Storage**: FileManager, UserDefaults
- **Logging**: Custom multi-level logging system
- **Internationalization**: xcstrings catalog

---

## Architecture

### Design Patterns

- **MVVM Architecture**: Clear separation of concerns
- **Singleton Pattern**: Shared managers (VersionManager, DownloadManager)
- **Async/Await**: Modern concurrency with Swift Concurrency
- **Protocol-Oriented**: Flexible and testable code structure

### Key Components

1. **VersionManager**
   - Manages version manifest and caching
   - Handles version inheritance
   - Parses version JSON data

2. **DownloadManager**
   - Concurrent download queue
   - Progress tracking and reporting
   - SHA1 integrity verification
   - Proxy configuration support

3. **ProxyManager**
   - Configures HTTP/HTTPS/SOCKS5 proxies
   - Tests proxy connectivity
   - Manages proxy state

4. **Logger**
   - Multi-level logging (Debug, Info, Warning, Error)
   - File-based log storage
   - Console output with timestamps

---

## Download Information

### File Locations

```
~/.minecraft/
├── versions/          # Version files
│   └── {version}/
│       ├── {version}.jar
│       └── {version}.json
├── libraries/         # Library dependencies
├── assets/           # Game assets
│   ├── indexes/
│   └── objects/
└── logs/             # Launcher logs
```

### Disk Space Requirements

- Single version: ~500MB - 1GB
- Complete setup: 5GB+ recommended
- Assets are shared across versions

### Network Requirements

- Stable internet connection required
- Mojang servers are located overseas
- Proxy recommended for optimal speed in some regions

---

## Development

### Completed Features

- [x] Version list fetching and caching
- [x] Version details parsing
- [x] Version inheritance handling
- [x] Multi-threaded download system
- [x] SHA1 integrity verification
- [x] Real-time progress tracking
- [x] Comprehensive logging system
- [x] Test interface with visual table
- [x] Version filtering by type
- [x] Proxy support (HTTP/HTTPS/SOCKS5)
- [x] Full internationalization (EN/ZH-CN)
- [x] Installation status checking

### Planned Features

- [ ] Game launch engine
- [ ] Microsoft account authentication
- [ ] Complete launcher UI redesign
- [ ] Configuration management system
- [ ] Mod loader support (Forge/Fabric/Quilt)
- [ ] Profile management
- [ ] Auto-update functionality
- [ ] Resource pack management
- [ ] Shader pack support
- [ ] Server management

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Guidelines

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## License

This project is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0) - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

[⬆ Back to Top](#minecraft-launcher)

</div>

