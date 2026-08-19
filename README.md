# RoPi SSH Manager Pro

Cross-platform modern SSH client and server management desktop application built for macOS, Windows, and Linux.

Developed by **RoPi LLC**.

## Features

- **Categorized Server Management**: Organize servers by categories with custom colors, icons, and tags.
- **One-Click Instant Connect**: Built-in tabbed terminal emulator powered by `xterm` and `dartssh2`.
- **Encrypted Local SQLite Database**: All credentials (passwords, private keys, passphrases) are encrypted using AES-256 with PBKDF2 key derivation.
- **Portable Mode**: Database stored in `./data/ssh_manager.db` for full USB/directory portability.
- **Master Password Security**: Optional master password lock and automatic inactivity timeout.
- **Quick Snippet Commands**: One-click quick server command dispatch (`htop`, `docker ps`, `df -h`, etc.).
- **Encrypted Backup & Restore**: Cross-platform JSON backup export and import.

## Building from Source

### Requirements
- Flutter SDK (3.x or higher)
- Visual Studio 2022 (Windows desktop development) / Xcode (macOS) / Clang & GTK3 (Linux)

### Development
```bash
flutter pub get
flutter run -d windows    # For Windows
flutter run -d macos      # For macOS
flutter run -d linux      # For Linux
```

### Production Build
```bash
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

## Security & Architecture

All sensitive authentication payloads are encrypted at rest using AES-256 (CBC/GCM) before being persisted to the SQLite database. Keys are stretched through 5,000 iterations of SHA-256 (PBKDF2 style) with salted hashes.

## License

Copyright (C) 2026 RoPi LLC. All rights reserved.
