#!/usr/bin/env sh
set -eu

DISK_IMG="${1:-build/disk-pm-t2.img}"
TIMEOUT_SECONDS="${QEMU_TIMEOUT_SECONDS:-3}"

if [ ! -f "$DISK_IMG" ]; then
    echo "FAIL: disk image not found: $DISK_IMG"
    exit 1
fi

if ! command -v qemu-system-i386 >/dev/null 2>&1; then
    echo "FAIL: qemu-system-i386 is not installed"
    exit 1
fi

LOG_FILE="build/qemu-pm-t2-debug.log"
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

if grep -q 'PM_OK' "$LOG_FILE"; then
    echo "FAIL: protected-mode success marker unexpectedly present"
    cat "$LOG_FILE"
    exit 1
fi

if grep -q 'P1' "$LOG_FILE"; then
    echo "PASS: protected-mode A20 failure path verified (P1)"
    exit 0
fi

echo "FAIL: protected-mode marker P1 not detected"
cat "$LOG_FILE"
exit 1