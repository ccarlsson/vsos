#!/usr/bin/env sh
set -eu

BOOT_BIN="${1:-build/boot.bin}"
KERNEL_BIN="${2:-build/kernel.bin}"
TIMEOUT_SECONDS="${QEMU_TIMEOUT_SECONDS:-3}"

if [ ! -f "$BOOT_BIN" ]; then
    echo "FAIL: boot sector not found: $BOOT_BIN"
    exit 1
fi

if [ ! -f "$KERNEL_BIN" ]; then
    echo "FAIL: kernel payload not found: $KERNEL_BIN"
    exit 1
fi

if ! command -v qemu-system-i386 >/dev/null 2>&1; then
    echo "FAIL: qemu-system-i386 is not installed"
    exit 1
fi

DISK_IMG="build/disk-t3.img"
LOG_FILE="build/qemu-t3-debug.log"
rm -f "$DISK_IMG" "$LOG_FILE"

# Build a normal image then corrupt one kernel sector to trigger E1.
dd if=/dev/zero of="$DISK_IMG" bs=512 count=2880 status=none
dd if="$BOOT_BIN" of="$DISK_IMG" conv=notrunc status=none
dd if="$KERNEL_BIN" of="$DISK_IMG" bs=512 seek=1 conv=notrunc status=none
dd if=/dev/zero of="$DISK_IMG" bs=512 seek=1 count=1 conv=notrunc status=none

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

if grep -q 'KERNEL_OK' "$LOG_FILE"; then
    echo "FAIL: kernel unexpectedly reached success path"
    cat "$LOG_FILE"
    exit 1
fi

if grep -q 'E1' "$LOG_FILE"; then
    echo "PASS: disk read failure path verified (E1)"
    exit 0
fi

echo "FAIL: disk error marker E1 not found"
cat "$LOG_FILE"
exit 1
