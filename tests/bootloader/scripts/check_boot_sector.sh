#!/usr/bin/env sh
set -eu

BOOT_BIN="${1:-build/boot.bin}"

if [ ! -f "$BOOT_BIN" ]; then
    echo "FAIL: boot sector not found: $BOOT_BIN"
    exit 1
fi

size="$(wc -c < "$BOOT_BIN" | tr -d ' ')"
if [ "$size" != "512" ]; then
    echo "FAIL: expected 512 bytes, got $size"
    exit 1
fi

sig="$(od -An -tx1 -j510 -N2 "$BOOT_BIN" | tr -d ' \n')"
if [ "$sig" != "55aa" ]; then
    echo "FAIL: expected signature 55aa at bytes 510-511, got $sig"
    exit 1
fi

echo "PASS: $BOOT_BIN is 512 bytes and has signature 0x55AA"
