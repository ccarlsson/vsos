#!/bin/bash

# VGA-T6: Scrolling Test
# Validates that the VGA console scrolls when output exceeds row 24
# Expected marker: VGA_SCROLL_OK

DISK_IMG="${1:-.}"
QEMU_TIMEOUT_SECONDS="${QEMU_TIMEOUT_SECONDS:-3}"
DEBUG_LOG="build/qemu-vga-t6-debug.log"

timeout "$QEMU_TIMEOUT_SECONDS" qemu-system-i386 \
    -drive format=raw,file="$DISK_IMG" \
    -debugcon file:"$DEBUG_LOG" \
    -display none \
    2>/dev/null

if grep -q "VGA_SCROLL_OK" "$DEBUG_LOG"; then
    echo "PASS: VGA scrolling verified (VGA_SCROLL_OK)"
    exit 0
else
    echo "FAIL: VGA_SCROLL_OK marker not found"
    exit 1
fi
