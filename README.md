# monoshine

A Debian-based Termux distribution with Thai language support and security tools.

## Overview

monoshine is a custom Debian rootfs designed for Termux on Android. It provides:

- **Debian trixie** base (arm64/aarch64)
- **Thai language support** - fonts, input methods, locales
- **Security tools** - nmap, rkhunter, lynis, fail2ban, nftables
- **Termux-optimized** - proot-friendly, no systemd dependency

## Installation

In Termux:

```bash
# Download the latest release
curl -L https://github.com/monoshine/monoshine/releases/latest/download/monoshine-arm64.tar.xz -o monoshine.tar.xz

# Extract and run
proot-distro install monoshine
proot-distro login monoshine
```

Or using the standalone setup:

```bash
# Manual extraction
mkdir -p ~/.local/share/proot-distro/installed/monoshine
tar -xJf monoshine-arm64.tar.xz -C ~/.local/share/proot-distro/installed/monoshine

# Login
proot-distro login monoshine
```

## Build

```bash
./build.sh
```

The build output is placed in `out/`.

### Build Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DEBIAN_ARCH` | `arm64` | Target architecture (arm64, armhf, amd64) |
| `DEBIAN_SUITE` | `trixie` | Debian suite to bootstrap |
| `OUTPUT_DIR` | `./out` | Output directory for tarball |

### Prerequisites

On Debian/Ubuntu:
```bash
sudo apt-get install debootstrap qemu-user-static xz-utils
```

## Testing

### Automated Testing

```bash
# Run tests locally (requires debootstrap)
DEBIAN_ARCH=arm64 ./build.sh
```

GitHub Actions runs automated tests on every push and pull request.

### Manual Testing

```bash
# Extract and inspect
tar -xJf out/monoshine-arm64.tar.xz -C /tmp/monoshine-test

# Run a command in chroot (with qemu for cross-arch)
chroot /tmp/monoshine-test /usr/local/bin/monoshine-info

# Verify Thai locale
chroot /tmp/monoshine-test locale
```

## Features

### Thai Language Support

- **Thai fonts**: Noto Sans Thai, Noto Sans Thai UI, DejaVu (fallback)
- **Thai locale**: `th_TH.UTF-8` enabled and set as default
- **Input methods**: ibus with ibus-libthai for predictive Thai text input
- **Keyboard layout**: Thai XKB layout
- **Font rendering**: Proper Thai vowel positioning via fontconfig + HarfBuzz
- **Console**: Terminus font with Thai glyph support

### Security Tools

| Tool | Purpose |
|------|---------|
| nmap | Network discovery and security auditing |
| rkhunter | Rootkit detection |
| lynis | Security auditing and system hardening |
| gnupg | Encryption and signing |
| openssh-client | Secure remote access (client) |
| nftables | Modern firewall framework |
| fail2ban | Intrusion prevention via log monitoring |
| clamav | Antivirus scanning |
| chkrootkit | Rootkit detection |

### Termux Integration

- PRoot-compatible (no systemd required for base functionality)
- ARM64 optimized for Android devices
- Lightweight base image for mobile use

## Project Structure

```
monoshine/
├── README.md              # This file
├── build.sh               # Build script (debootstrap-based)
├── packages.list          # Additional packages to install
├── AGENTS.md              # Development guide
├── release-notes.md       # Release notes template
├── .gitignore
├── .github/
│   └── workflows/
│       ├── build.yml      # CI: Build tarball for multiple arches
│       ├── test.yml       # CI: Test built rootfs
│       └── release.yml    # CI: Create GitHub Release
├── etc/
│   ├── apt/
│   │   └── sources.list   # Debian sources
│   ├── locale.gen         # Thai + English locales
│   ├── environment        # Env vars (Thai locale, ibus IM)
│   └── fonts/
│       └── 99-thai.conf   # Fontconfig Thai rendering config
└── termux-boot/
    └── start-monoshine.sh # Termux boot script
```

## License

MIT
