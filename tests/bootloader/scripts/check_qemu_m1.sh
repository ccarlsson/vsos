#!/usr/bin/env sh
set -eu

BOOT_BIN="${1:-build/boot.bin}"
TIMEOUT_SECONDS="${QEMU_TIMEOUT_SECONDS:-3}"

if [ ! -f "$BOOT_BIN" ]; then
    echo "FAIL: boot sector not found: $BOOT_BIN"
    exit 1
fi

if ! command -v qemu-system-i386 >/dev/null 2>&1; then
    echo "FAIL: qemu-system-i386 is not installed"
    exit 1
fi

LOG_FILE="build/qemu-debug.log"
rm -f "$LOG_FILE"

timeout -k 1s "${TIMEOUT_SECONDS}s" qemu-system-i386 \
    -drive file="$BOOT_BIN",format=raw,if=floppy \
    -display none \
    -monitor none \
    -serial none \
    -debugcon file:"$LOG_FILE" \
    -global isa-debugcon.iobase=0xe9 \
    -no-reboot \
    -no-shutdown >/dev/null 2>&1 || true

if [ -f "$LOG_FILE" ] && grep -q 'VSOS M1' "$LOG_FILE"; then
    echo "PASS: QEMU boot marker detected (VSOS M1)"
    exit 0
fi

echo "FAIL: QEMU boot marker not detected"
if [ -f "$LOG_FILE" ]; then
    cat "$LOG_FILE"
fi
exit 1
