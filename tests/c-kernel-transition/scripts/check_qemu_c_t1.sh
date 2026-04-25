#!/bin/sh
set -eu

DISK_IMAGE="$1"
TIMEOUT_SECONDS="${QEMU_TIMEOUT_SECONDS:-3}"
LOG_FILE="build/qemu-c-t1-debug.log"

rm -f "$LOG_FILE"

timeout -k 1s "${TIMEOUT_SECONDS}s" qemu-system-i386 \
    -drive format=raw,file="$DISK_IMAGE",if=floppy \
    -boot a \
    -nographic \
    -monitor none \
    -serial none \
    -debugcon file:"$LOG_FILE" \
    -global isa-debugcon.iobase=0xe9 \
    -no-reboot \
    -no-shutdown \
    >/dev/null 2>&1 || true

if ! [ -f "$LOG_FILE" ]; then
    echo "FAIL: QEMU did not produce a debug log"
    exit 1
fi

if ! grep -q 'PM_OK' "$LOG_FILE"; then
    echo "FAIL: protected-mode marker PM_OK not detected before C handoff"
    exit 1
fi

if grep -q 'C_ENTRY_OK' "$LOG_FILE"; then
    echo "PASS: C entry marker verified (C_ENTRY_OK)"
    exit 0
fi

echo "FAIL: C entry marker C_ENTRY_OK not detected"
exit 1
