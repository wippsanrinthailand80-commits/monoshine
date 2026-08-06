#!/usr/bin/env bash
# Termux boot script - starts monoshine proot-distro on device boot
# Requires: Termux:Boot app installed

echo "[monoshine] Starting on boot..."

if ! command -v proot-distro >/dev/null 2>&1; then
    echo "[monoshine] proot-distro not found, skipping"
    exit 0
fi

if ! proot-distro list | grep -q monoshine; then
    echo "[monoshine] monoshine not installed, skipping"
    exit 0
fi

proot-distro login monoshine --shared-tmp -- bash -c 'echo "monoshine started at $(date)" >> /var/log/monoshine-boot.log' 2>&1

echo "[monoshine] Boot init complete"
