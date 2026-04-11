#!/bin/bash

# VGA-T2: Single character output test
# Verify a single character is placed at cursor and cursor advances.
# Expected marker: VGA_CHAR_OK

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
    -debugcon file:build/qemu-vga-t2-debug.log \
    -display none \
    -no-reboot \
    2>&1 || true

# Check for required marker
if grep -q "VGA_CHAR_OK" build/qemu-vga-t2-debug.log; then
    echo "PASS: Character output verified (VGA_CHAR_OK)"
    exit 0
else
    echo "FAIL: Character output marker not detected"
    cat build/qemu-vga-t2-debug.log || true
    exit 1
fi
