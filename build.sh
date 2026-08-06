#!/usr/bin/env bash
set -euo pipefail

# monoshine - Debian-based Termux distro build script
# Creates a minimal Debian rootfs with Thai language support and security tools
#
# Environment variables:
#   DEBIAN_SUITE  - Debian suite (default: trixie)
#   DEBIAN_ARCH   - Target architecture (default: arm64)
#   OUTPUT_DIR    - Output directory (default: ./out)

DISTRO_NAME="monoshine"
DEBIAN_SUITE="${DEBIAN_SUITE:-trixie}"
DEBIAN_ARCH="${DEBIAN_ARCH:-arm64}"
OUTPUT_DIR="${OUTPUT_DIR:-./out}"
PACKAGES_LIST="packages.list"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
    echo "[build] $*"
}

BUILD_DIR=$(mktemp -d)
cleanup() {
    log "Cleaning up build directory: ${BUILD_DIR}"
    rm -rf "${BUILD_DIR}"
}
trap cleanup EXIT

HOST_ARCH=$(dpkg --print-architecture)

check_deps() {
    local missing=()
    for tool in debootstrap; do
        command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
    done
    if [[ "$DEBIAN_ARCH" != "$HOST_ARCH" ]]; then
        if ! command -v qemu-arm-static >/dev/null 2>&1; then
            missing+=("qemu-user-static")
        fi
    fi
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR: Missing dependencies: ${missing[*]}"
        log "Install with: sudo apt-get install -y ${missing[*]}"
        exit 1
    fi
}

copy_qemu() {
    if [[ "$DEBIAN_ARCH" != "$HOST_ARCH" ]]; then
        local qemu_binary
        qemu_binary="/usr/bin/qemu-${DEBIAN_ARCH}-static"
        if [[ -x "$qemu_binary" ]]; then
            log "Copying qemu-static for cross-architecture chroot"
            cp "$qemu_binary" "${BUILD_DIR}/rootfs/usr/bin/"
        fi
    fi
}

mount_chroot() {
    local rootfs="${BUILD_DIR}/rootfs"
    mount -t proc proc "${rootfs}/proc" 2>/dev/null || true
    mount -t sysfs sysfs "${rootfs}/sys" 2>/dev/null || true
    mount -t devtmpfs devtmpfs "${rootfs}/dev" 2>/dev/null || true
    mount -o bind /dev "${rootfs}/dev" 2>/dev/null || true
}

umount_chroot() {
    local rootfs="${BUILD_DIR}/rootfs"
    umount "${rootfs}/dev" 2>/dev/null || true
    umount "${rootfs}/proc" 2>/dev/null || true
    umount "${rootfs}/sys" 2>/dev/null || true
}

bootstrap_base() {
    log "Bootstrapping Debian ${DEBIAN_SUITE} (${DEBIAN_ARCH})..."
    local rootfs="${BUILD_DIR}/rootfs"
    mkdir -p "${rootfs}/dev" "${rootfs}/proc" "${rootfs}/sys" "${rootfs}/tmp"

    debootstrap --arch="${DEBIAN_ARCH}" --foreign --include=ca-certificates,apt,dpkg "${DEBIAN_SUITE}" "${rootfs}" "http://deb.debian.org/debian"
    copy_qemu

    log "Running debootstrap second stage..."
    chroot "${rootfs}" /debootstrap/debootstrap --second-stage
    mount_chroot

    log "Configuring apt..."
    cp "${SCRIPT_DIR}/etc/apt/sources.list" "${rootfs}/etc/apt/sources.list"
    chroot "${rootfs}" apt-get update -qq
    chroot "${rootfs}" apt-get upgrade -y -qq

    log "Base system bootstrapped successfully."
}

install_packages() {
    log "Installing packages from ${PACKAGES_LIST}..."
    local rootfs="${BUILD_DIR}/rootfs"

    local pkgs=()
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="$(echo "$line" | sed 's/#.*//' | xargs)"
        [[ -n "$line" ]] && pkgs+=("$line")
    done < "${SCRIPT_DIR}/${PACKAGES_LIST}"

    if [[ ${#pkgs[@]} -gt 0 ]]; then
        log "Installing ${#pkgs[@]} packages..."
        chroot "${rootfs}" apt-get install -y --no-install-recommends -qq "${pkgs[@]}" || {
            log "WARNING: Some packages failed to install"
            chroot "${rootfs}" apt-get install -y --no-install-recommends "${pkgs[@]}" 2>&1 || true
        }
        chroot "${rootfs}" apt-get clean
        rm -rf "${rootfs}/var/lib/apt/lists/"*
    fi

    log "Packages installed successfully."
}

configure_system() {
    log "Configuring system..."
    local rootfs="${BUILD_DIR}/rootfs"

    log "Setting up locales..."
    cp "${SCRIPT_DIR}/etc/locale.gen" "${rootfs}/etc/locale.gen"
    chroot "${rootfs}" locale-gen || log "WARNING: locale-gen failed"

    log "Setting up environment..."
    cp "${SCRIPT_DIR}/etc/environment" "${rootfs}/etc/environment"

    echo "monoshine" > "${rootfs}/etc/hostname"

    log "Setting up font configuration..."
    mkdir -p "${rootfs}/etc/fonts/conf.d"
    cp "${SCRIPT_DIR}/etc/fonts/99-thai.conf" "${rootfs}/etc/fonts/conf.d/99-thai.conf"

    echo 'root:' | chroot "${rootfs}" chpasswd || true

    mkdir -p "${rootfs}/tmp"
    chmod 1777 "${rootfs}/tmp"

    log "Installing info scripts..."
    mkdir -p "${rootfs}/usr/local/bin"
    cat > "${rootfs}/usr/local/bin/monoshine-info" << 'INFOSCRIPT'
#!/bin/sh
echo "monoshine - Debian-based Termux distro"
echo "Architecture: $(uname -m)"
locale 2>/dev/null || true
INFOSCRIPT
    chmod +x "${rootfs}/usr/local/bin/monoshine-info"

    umount_chroot
    log "System configured successfully."
}

package_distro() {
    log "Packaging distribution..."
    local rootfs="${BUILD_DIR}/rootfs"
    mkdir -p "${SCRIPT_DIR}/${OUTPUT_DIR}"

    local tarball="${SCRIPT_DIR}/${OUTPUT_DIR}/${DISTRO_NAME}-${DEBIAN_ARCH}.tar.xz"

    rm -f "${rootfs}/usr/bin/qemu-"*
    rm -rf "${rootfs}/debootstrap"
    rm -rf "${rootfs}/var/lib/apt/lists"
    rm -rf "${rootfs}/usr/share/doc" "${rootfs}/usr/share/man" "${rootfs}/usr/share/info"

    tar -cJf "${tarball}" -C "${rootfs}" .

    local size
    size="$(du -h "${tarball}" | cut -f1)"
    log "Created ${tarball} (${size})"
    log "Packaging complete."
}

main() {
    log "=== monoshine builder ==="
    log "Suite: ${DEBIAN_SUITE} | Arch: ${DEBIAN_ARCH} | Host: ${HOST_ARCH}"
    log "Build dir: ${BUILD_DIR}"

    check_deps
    bootstrap_base
    install_packages
    configure_system
    package_distro

    log "=== Build complete ==="
    log "Output: ${OUTPUT_DIR}/"
    ls -lh "${SCRIPT_DIR}/${OUTPUT_DIR}/"
}

main "$@"
