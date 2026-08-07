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

# Use sudo if not running as root
if [[ "$(id -u)" -eq 0 ]]; then
    SUDO=""
else
    SUDO="sudo"
fi

log() {
    echo "[build] $*"
}

BUILD_DIR=$(mktemp -d)
cleanup() {
    log "Cleaning up build directory: ${BUILD_DIR}"
    $SUDO rm -rf "${BUILD_DIR}"
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
            $SUDO cp "$qemu_binary" "${BUILD_DIR}/rootfs/usr/bin/"
        fi
    fi
}

mount_chroot() {
    local rootfs="${BUILD_DIR}/rootfs"
    $SUDO mount -t proc proc "${rootfs}/proc" 2>/dev/null || true
    $SUDO mount -t sysfs sysfs "${rootfs}/sys" 2>/dev/null || true
    $SUDO mount -o bind /dev "${rootfs}/dev" 2>/dev/null || true
    $SUDO mount -o bind /run "${rootfs}/run" 2>/dev/null || true
}

umount_chroot() {
    local rootfs="${BUILD_DIR}/rootfs"
    $SUDO umount "${rootfs}/run" 2>/dev/null || true
    $SUDO umount "${rootfs}/dev" 2>/dev/null || true
    $SUDO umount "${rootfs}/proc" 2>/dev/null || true
    $SUDO umount "${rootfs}/sys" 2>/dev/null || true
}

bootstrap_base() {
    log "Bootstrapping Debian ${DEBIAN_SUITE} (${DEBIAN_ARCH})..."
    local rootfs="${BUILD_DIR}/rootfs"
    $SUDO mkdir -p "${rootfs}/dev" "${rootfs}/proc" "${rootfs}/sys" "${rootfs}/tmp" "${rootfs}/run"

    $SUDO debootstrap --arch="${DEBIAN_ARCH}" --foreign --include=ca-certificates,apt,dpkg "${DEBIAN_SUITE}" "${rootfs}" "http://deb.debian.org/debian"
    copy_qemu

    log "Running debootstrap second stage..."
    $SUDO chroot "${rootfs}" /debootstrap/debootstrap --second-stage

    mount_chroot

    log "Configuring apt..."
    $SUDO cp "${SCRIPT_DIR}/etc/apt/sources.list" "${rootfs}/etc/apt/sources.list"
    $SUDO chroot "${rootfs}" apt-get update -qq
    $SUDO chroot "${rootfs}" apt-get upgrade -y -qq

    umount_chroot
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
        mount_chroot
        $SUDO chroot "${rootfs}" apt-get install -y --no-install-recommends -qq "${pkgs[@]}" || {
            log "WARNING: Some packages failed to install, retrying..."
            $SUDO chroot "${rootfs}" apt-get install -y --no-install-recommends "${pkgs[@]}" 2>&1 || true
        }
        $SUDO chroot "${rootfs}" apt-get clean
        $SUDO rm -rf "${rootfs}/var/lib/apt/lists/"*
        umount_chroot
    fi

    log "Packages installed successfully."
}

configure_system() {
    log "Configuring system..."
    local rootfs="${BUILD_DIR}/rootfs"

    log "Setting up locales..."
    $SUDO cp "${SCRIPT_DIR}/etc/locale.gen" "${rootfs}/etc/locale.gen"
    $SUDO chroot "${rootfs}" locale-gen || log "WARNING: locale-gen failed"

    log "Setting up environment..."
    $SUDO cp "${SCRIPT_DIR}/etc/environment" "${rootfs}/etc/environment"

    $SUDO sh -c "echo 'monoshine' > ${rootfs}/etc/hostname"

    log "Setting up font configuration..."
    $SUDO mkdir -p "${rootfs}/etc/fonts/conf.d"
    $SUDO cp "${SCRIPT_DIR}/etc/fonts/99-thai.conf" "${rootfs}/etc/fonts/conf.d/99-thai.conf"

    $SUDO sh -c "echo 'root:' | chroot ${rootfs} chpasswd" || true

    $SUDO mkdir -p "${rootfs}/tmp"
    $SUDO chmod 1777 "${rootfs}/tmp"

    log "Installing info scripts..."
    $SUDO mkdir -p "${rootfs}/usr/local/bin"
    local inst_script="${BUILD_DIR}/monoshine-info"
    cat > "${inst_script}" << 'INSTEOF'
#!/bin/sh
echo "monoshine - Debian-based Termux distro"
echo "Architecture: $(uname -m)"
locale 2>/dev/null || true
INSTEOF
    $SUDO cp "${inst_script}" "${rootfs}/usr/local/bin/monoshine-info"
    $SUDO chmod +x "${rootfs}/usr/local/bin/monoshine-info"

    log "System configured successfully."
}

package_distro() {
    log "Packaging distribution..."
    local rootfs="${BUILD_DIR}/rootfs"
    mkdir -p "${SCRIPT_DIR}/${OUTPUT_DIR}"

    local tarball="${SCRIPT_DIR}/${OUTPUT_DIR}/${DISTRO_NAME}-${DEBIAN_ARCH}.tar.xz"

    $SUDO rm -f "${rootfs}/usr/bin/qemu-"*
    $SUDO rm -rf "${rootfs}/debootstrap"
    $SUDO rm -rf "${rootfs}/var/lib/apt/lists"
    $SUDO rm -rf "${rootfs}/dev"
    $SUDO rm -rf "${rootfs}/usr/share/doc" "${rootfs}/usr/share/man" "${rootfs}/usr/share/info"

    $SUDO tar -C "${rootfs}" -cJf "${tarball}" .
    $SUDO chown "$(id -u):$(id -g)" "${tarball}"

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
