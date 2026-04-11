#!/bin/bash

# VGA-T5: Column wrapping test
# Verify cursor wraps to next row when column exceeds 79.
# Expected marker: VGA_WRAP_OK

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
    -debugcon file:build/qemu-vga-t5-debug.log \
    -no-reboot \
    2>&1 || true

# Check for required marker
if grep -q "VGA_WRAP_OK" build/qemu-vga-t5-debug.log; then
    echo "PASS: Column wrapping verified (VGA_WRAP_OK)"
    exit 0
else
    echo "FAIL: Column wrapping marker not detected"
    cat build/qemu-vga-t5-debug.log || true
    exit 1
fi
