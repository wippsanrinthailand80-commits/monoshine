#!/usr/bin/env bash
set -euo pipefail

# MAD EL OS - Build Script
# Builds a custom Arch Linux ISO with Thai language support
# and reduced cybersecurity tools

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-${SCRIPT_DIR}/out}"
WORK_DIR="${WORK_DIR:-/tmp/madel-work}"

# Check architecture
DEBIAN_ARCH="${DEBIAN_ARCH:-x86_64}"
KERNEL_ARCH="${DEBIAN_ARCH}"
if [[ "${DEBIAN_ARCH}" == "aarch64" || "${DEBIAN_ARCH}" == "arm64" ]]; then
    KERNEL_ARCH="arm64"
fi

# Build the ISO
echo "Building MAD EL OS ISO..."
echo "Architecture: ${KERNEL_ARCH}"
echo "Output directory: ${OUTPUT_DIR}"
echo "Work directory: ${WORK_DIR}"

# Clean previous build artifacts
rm -rf "${WORK_DIR}" "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

# Run mkarchiso
# -v: verbose output
# -w: working directory (tmpfs recommended for performance)
# -o: output directory
mkarchiso -v \
    -w "${WORK_DIR}" \
    -o "${OUTPUT_DIR}" \
    -r "${SCRIPT_DIR}"

echo ""
echo "Build complete!"
echo "ISO image: $(ls -lh ${OUTPUT_DIR}/madel-*.iso 2>/dev/null | awk '{print $NF}')"
echo ""
echo "To test the ISO with QEMU:"
echo "  run_archiso -i ${OUTPUT_DIR}/madel-*.iso"
