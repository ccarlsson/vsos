#!/usr/bin/env sh
set -eu

DISK_IMG="${1:-build/disk.img}"
TIMEOUT_SECONDS="${QEMU_TIMEOUT_SECONDS:-3}"

if [ ! -f "$DISK_IMG" ]; then
    echo "FAIL: disk image not found: $DISK_IMG"
    exit 1
fi

if ! command -v qemu-system-i386 >/dev/null 2>&1; then
    echo "FAIL: qemu-system-i386 is not installed"
    exit 1
fi

LOG_FILE="build/qemu-ih-t1-debug.log"
rm -f "$LOG_FILE"

timeout -k 1s "${TIMEOUT_SECONDS}s" qemu-system-i386 \
    -drive file="$DISK_IMG",format=raw,if=floppy \
    -display none \
    -monitor none \
    -serial none \
    -debugcon file:"$LOG_FILE" \
    -global isa-debugcon.iobase=0xe9 \
    -no-reboot \
    -no-shutdown >/dev/null 2>&1 || true

if [ ! -f "$LOG_FILE" ]; then
    echo "FAIL: no QEMU debug output captured"
    exit 1
fi

if grep -q 'IH_OK' "$LOG_FILE"; then
    echo "PASS: interrupt handler verified (IH_OK)"
    exit 0
fi

echo "FAIL: interrupt marker IH_OK not detected"
cat "$LOG_FILE"
exit 1
