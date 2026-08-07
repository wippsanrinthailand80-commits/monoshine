# monoshine Release Notes

## Version 1.0.0

### Overview
monoshine is a Debian-based Termux distro with:
- Thai language support (correct vowel positioning, no floating or sinking vowels)
- Reduced cybersecurity tools (only essential utilities)

### Thai Language Support
- Locales: `th_TH.UTF-8` and `en_US.UTF-8`
- Fonts: Noto Sans Thai (with proper OpenType GPOS/GDEF tables), DejaVu, Terminus
- Input Method: ibus-libthai for predictive Thai input
- Font Rendering: HarfBuzz with proper OpenType shaping for correct mark positioning

### Security Tools (Reduced Set)
- `nmap` - Network discovery and security auditing
- `rkhunter` - Rootkit detection
- `lynis` - Security auditing and hardening
- `gnupg` - Encryption and signing
- `openssh` - Secure remote access
- `nftables` - Modern firewall framework
- `fail2ban` - Intrusion prevention
- `ca-certificates` - TLS certificate management

### Build Information
- Base: Debian trixie
- Architectures: arm64, armhf, amd64
- Build tool: debootstrap
- Package format: tar.xz rootfs archive

### Termux Integration
- Compatible with `proot-distro` and `termux-boot`
- Includes `start-monoshine.sh` boot script for Termux integration