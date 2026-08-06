# MAD EL OS Release Notes

## Version 1.0.0

### Overview
MAD EL OS is a custom Arch Linux ISO with:
- Thai language support (correct vowel positioning, no floating/sinking vowels)
- Reduced cybersecurity tools (only essential utilities)

### Thai Language Support
- Locales: `th_TH.UTF-8` and `en_US.UTF-8`
- Fonts: Noto Sans Thai (with proper OpenType shaping), DejaVu, Terminus
- Input Method: Fcitx5 with libthai predictive Thai input
- Font Rendering: HarfBuzz with GPOS/GDEF tables for correct mark positioning
- Keyboard: Thai XKB layout loaded at boot

### Security Tools (Reduced Set)
- `nmap` - Network discovery and security auditing
- `rkhunter` - Rootkit detection
- `lynis` - Security auditing and hardening
- `gnupg` - Encryption and signing
- `openssh` - Secure remote access
- `nftables` - Modern firewall framework
- `fail2ban` - Intrusion prevention
- `ca-certificates-utils` - TLS certificate management

### Build Information
- Base: Arch Linux (rolling release)
- Architecture: x86_64
- Boot modes: BIOS (syslinux), UEFI (systemd-boot, GRUB)
- Build tool: archiso + mkarchiso

### Known Issues
- `ibus-libthai` (IBus Thai input engine) is not available in official Arch repos; `fcitx5-libthai` is used instead.
- Noto Sans Thai may not render complex consonant+vowel+tone-mark combinations perfectly in all terminal emulators. GUI applications with proper HarfBuzz support render correctly.
