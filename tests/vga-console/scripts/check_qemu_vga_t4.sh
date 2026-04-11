#!/bin/bash

# VGA-T4: Newline handling test
# Verify newline character advances to next row and resets column.
# Expected marker: VGA_NL_OK

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
    -debugcon file:build/qemu-vga-t4-debug.log \
    -display none \
    -no-reboot \
    2>&1 || true

# Check for required marker
if grep -q "VGA_NL_OK" build/qemu-vga-t4-debug.log; then
    echo "PASS: Newline handling verified (VGA_NL_OK)"
    exit 0
else
    echo "FAIL: Newline handling marker not detected"
    cat build/qemu-vga-t4-debug.log || true
    exit 1
fi
