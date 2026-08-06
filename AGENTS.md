# AGENTS.md - Development Guide

## Project
MAD EL OS: A custom Arch Linux ISO with Thai language support and reduced cybersecurity tools.

## Build
- `./build.sh` - builds the ISO locally
- Environment variables:
  - `OUTPUT_DIR` (default: ./out) - output directory
  - `WORK_DIR` (default: /tmp/madel-work) - working directory for mkarchiso

## Dependencies (for building)
- archiso
- edk2-ovmf (for UEFI boot support)
- qemu-desktop (for testing)
- Root/sudo privileges (mkarchiso requires root)

## Testing
- `test.yml` GitHub Actions workflow runs package and configuration tests
- Manual testing:
  ```bash
  run_archiso -i out/madel-*.iso
  # or
  qemu-system-x86_64 -m 4G -cdrom out/madel-*.iso -boot d
  ```

## Verification
```bash
# Verify build artifacts
ls -lh out/
file out/madel-*.iso

# Inspect ISO contents
unsquashfs -l out/madel-*.iso
```

## Publishing
- Tag a commit with `v*` to trigger release workflow
- Release artifacts are uploaded to GitHub Releases
- GitHub Actions builds on Arch Linux using Docker

## Project Structure
```
madel/
├── profiledef.sh               # archiso profile definition
├── packages.x86_64             # Package list
├── pacman.conf                 # Build-time pacman config
├── build.sh                    # Build script
├── airootfs/
│   ├── etc/
│   │   ├── locale.gen
│   │   ├── locale.conf
│   │   ├── vconsole.conf
│   │   ├── environment
│   │   ├── os-release
│   │   ├── pacman.d/
│   │   ├── mkinitcpio.conf.d/
│   │   ├── fonts/conf.d/99-thai-render.conf
│   │   └── systemd/system/
│   └── root/
│       ├── .bashrc
│       └── .config/fcitx5/
├── syslinux/syslinux.cfg       # BIOS boot config
├── grub/grub.cfg               # GRUB config
└── efiboot/                    # UEFI systemd-boot config
```
