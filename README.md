# MAD EL OS

A custom Arch Linux-based ISO with reduced cybersecurity tools and full Thai language support, including correct vowel positioning (no floating or sinking vowels).

## Overview

MAD EL OS provides:

- **Arch Linux base** - Rolling release, minimal base system
- **Thai language support** - Locales, fonts, input methods, and proper text rendering
- **Reduced security tools** - Only essential cybersecurity utilities

## Thai Language Support

### Locale
- `th_TH.UTF-8` is enabled and set as the default system locale

### Fonts
- **Noto Sans Thai** - Primary font with proper OpenType `GPOS`/`GDEF` tables for correct mark positioning
- **DejaVu Sans** - Fallback font with Thai glyph coverage
- **Terminus** - Console font with Thai support

### Text Rendering (No Floating/Sinking Vowels)

Thai script requires complex text shaping to position vowel signs and tone marks correctly around consonant bases. MAD EL OS ensures proper rendering through:

1. **HarfBuzz** text shaping engine applies `GPOS` (Glyph Positioning) rules from the font
2. **Fontconfig** configuration (`99-thai-render.conf`) ensures Thai text always uses fonts with proper OpenType support
3. **Noto Sans Thai** contains proper `ccmp` (character composition), `mark` (mark-to-base), and `mkmk` (mark-to-mark) features

This prevents the common issues of:
- **Floating vowels** - Vowel signs positioned incorrectly above the baseline
- **Sinking vowels** - Vowel signs positioned incorrectly below the baseline
- **Misaligned tone marks** - MAITAIKHU, NIKHAHIT, and tone marks (U+0E48-U+0E4B) without proper stacking

### Input Method
- **Fcitx5** with **fcitx5-libthai** for predictive Thai text input
- Thai keyboard layout (XKB) loaded at boot
- Language toggle: Alt+Shift

## Security Tools (Reduced Set)

| Tool | Purpose |
|------|---------|
| nmap | Network discovery and security auditing |
| rkhunter | Rootkit detection |
| lynis | Security auditing and system hardening |
| gnupg | Encryption and signing |
| openssh | Secure remote access |
| nftables | Modern firewall framework |
| fail2ban | Intrusion prevention via log monitoring |
| ca-certificates-utils | TLS certificate management |

## Build

### Prerequisites (on Arch Linux host)

```bash
sudo pacman -S archiso mkinitcpio-archiso edk2-ovmf qemu-desktop
```

### Build

```bash
# Build the ISO
sudo ./build.sh

# Or build manually
sudo mkarchiso -v -w /tmp/madel-work -o ./out .

# With custom output directory
sudo OUTPUT_DIR=/path/to/output ./build.sh
```

Output is placed in `./out/madel-*.iso`.

### Testing

```bash
# Test with QEMU
run_archiso -i out/madel-*.iso

# Manual QEMU test
qemu-system-x86_64 -accel kvm \
    -m 4G \
    -cdrom out/madel-*.iso \
    -boot d
```

## Verification

```bash
# Verify build artifacts
ls -lh out/
file out/madel-*.iso

# Inspect rootfs contents
unsquashfs -l out/madel-*.iso
```

## Project Structure

```
madel/
├── profiledef.sh               # archiso profile definition
├── packages.x86_64             # Package list
├── pacman.conf                 # Build-time pacman config
├── build.sh                    # Build script
├── airootfs/                   # Root filesystem overlay
│   ├── etc/
│   │   ├── locale.gen          # Thai + English locales
│   │   ├── locale.conf         # Default: th_TH.UTF-8
│   │   ├── vconsole.conf       # Thai keyboard map
│   │   ├── environment         # Fcitx5 IM env vars
│   │   ├── os-release          # Custom OS branding
│   │   ├── pacman.d/
│   │   │   ├── hooks/
│   │   │   │   └── locale-gen.hook
│   │   │   └── mirrorlist      # Asia-optimized mirrors
│   │   ├── mkinitcpio.conf.d/
│   │   │   └── archiso.conf
│   │   ├── fonts/conf.d/
│   │   │   └── 99-thai-render.conf  # Thai font rendering config
│   │   └── systemd/system/
│   │       └── getty@tty1.service.d/
│   │           └── autologin.conf
│   └── root/
│       ├── .bashrc             # Thai-enabled terminal
│       └── .config/fcitx5/     # Thai input method config
├── syslinux/                   # BIOS boot config
│   └── syslinux.cfg
├── grub/                       # GRUB config (UEFI)
│   └── grub.cfg
└── efiboot/                    # systemd-boot config (UEFI)
    ├── loader.conf
    └── entries/
        └── archiso.conf
```

## License

MIT
