#!/usr/bin/env sh
set -eu

DISK_IMG="${1:-build/disk-hi-t2.img}"
TIMEOUT_SECONDS="${QEMU_TIMEOUT_SECONDS:-3}"

if [ ! -f "$DISK_IMG" ]; then
    echo "FAIL: disk image not found: $DISK_IMG"
    exit 1
fi

if ! command -v qemu-system-i386 >/dev/null 2>&1; then
    echo "FAIL: qemu-system-i386 is not installed"
    exit 1
fi

LOG_FILE="build/qemu-hi-t4-debug.log"
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

if ! grep -q 'HI_IRQ0_OK' "$LOG_FILE"; then
    echo "FAIL: IRQ0 path not functional (HI_IRQ0_OK missing)"
    cat "$LOG_FILE"
    exit 1
fi

if ! grep -q 'HI_TICKS_3' "$LOG_FILE"; then
    echo "FAIL: multi-tick liveness not verified (HI_TICKS_3 missing)"
    cat "$LOG_FILE"
    exit 1
fi

if grep -qE 'IX_00|IX_06|IX_13' "$LOG_FILE"; then
    echo "FAIL: unexpected exception marker detected (spurious IRQ or fault)"
    cat "$LOG_FILE"
    exit 1
fi

echo "PASS: IRQ mask discipline verified (IRQ0 functional, multi-tick alive, no spurious faults)"
exit 0
