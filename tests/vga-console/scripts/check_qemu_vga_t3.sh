#!/bin/bash

# VGA-T3: String output test
# Verify a null-terminated string is output correctly.
# Expected marker: VGA_STR_OK

set -e

IMAGE="$1"
: "${QEMU_TIMEOUT_SECONDS:=3}"

if [ -z "$IMAGE" ]; then
    echo "Usage: $0 <disk_image>"
    exit 1
fi

# Run QEMU and capture debugcon output
timeout "$QEMU_TIMEOUT_SECONDS" qemu-system-i386 \
    -drive format=raw,file="$IMAGE" \
    -debugcon file:build/qemu-vga-t3-debug.log \
    -no-reboot \
    2>&1 || true

# Check for required marker
if grep -q "VGA_STR_OK" build/qemu-vga-t3-debug.log; then
    echo "PASS: String output verified (VGA_STR_OK)"
    exit 0
else
    echo "FAIL: String output marker not detected"
    cat build/qemu-vga-t3-debug.log || true
    exit 1
fi
