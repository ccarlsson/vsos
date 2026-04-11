#!/bin/bash

# VGA-T1: Initialization test
# Verify VGA framebuffer is cleared and cursor reset on init.
# Expected marker: VGA_INIT_OK

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
    -debugcon file:build/qemu-vga-t1-debug.log \
    -no-reboot \
    2>&1 || true

# Check for required marker
if grep -q "VGA_INIT_OK" build/qemu-vga-t1-debug.log; then
    echo "PASS: VGA initialization verified (VGA_INIT_OK)"
    exit 0
else
    echo "FAIL: VGA initialization marker not detected"
    cat build/qemu-vga-t1-debug.log || true
    exit 1
fi
