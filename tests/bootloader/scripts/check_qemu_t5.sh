#!/usr/bin/env sh
set -eu

DISK_IMG="${1:-build/disk.img}"
EXPECTED_DL="${2:-}"
TIMEOUT_SECONDS="${QEMU_TIMEOUT_SECONDS:-3}"

if [ ! -f "$DISK_IMG" ]; then
    echo "FAIL: disk image not found: $DISK_IMG"
    exit 1
fi

if ! command -v qemu-system-i386 >/dev/null 2>&1; then
    echo "FAIL: qemu-system-i386 is not installed"
    exit 1
fi

LOG_FILE="build/qemu-t5-debug.log"
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

if ! grep -q 'KERNEL_OK' "$LOG_FILE"; then
    echo "FAIL: kernel marker missing"
    cat "$LOG_FILE"
    exit 1
fi

first_dl="$(grep -o 'DL=[0-9A-F][0-9A-F]' "$LOG_FILE" | sed -n '1p' | cut -d= -f2)"
second_dl="$(grep -o 'DL=[0-9A-F][0-9A-F]' "$LOG_FILE" | sed -n '2p' | cut -d= -f2)"

if [ -z "$first_dl" ] || [ -z "$second_dl" ]; then
    echo "FAIL: could not extract both bootloader and kernel DL values"
    cat "$LOG_FILE"
    exit 1
fi

if [ "$first_dl" != "$second_dl" ]; then
    echo "FAIL: DL mismatch across handoff (bootloader=$first_dl kernel=$second_dl)"
    cat "$LOG_FILE"
    exit 1
fi

if [ -n "$EXPECTED_DL" ] && [ "$second_dl" != "$EXPECTED_DL" ]; then
    echo "FAIL: propagated DL=$second_dl but expected DL=$EXPECTED_DL"
    cat "$LOG_FILE"
    exit 1
fi

echo "PASS: boot drive propagation verified (bootloader=$first_dl kernel=$second_dl)"
exit 0
