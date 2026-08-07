# MAD EL OS Release Notes

## Version 1.0.0

### Overview
MAD EL OS is a custom Arch Linux ISO with:
- Thai language support (correct vowel positioning, no floating or sinking vowels)
- Reduced cybersecurity tools (only essential utilities)

### Thai Language Support
- Locales: `th_TH.UTF-8` and `en_US.UTF-8`
- Fonts: Noto Sans Thai (with proper OpenType GPOS/GDEF tables), DejaVu, Terminus
- Input Method: Fcitx5 with fcitx5-libthai for predictive Thai input
- Font Rendering: HarfBuzz with proper OpenType shaping for correct mark positioning
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
