#!/usr/bin/env bash
set -eu

DISK_IMG="${1:-build/disk-kbd.img}"
TIMEOUT_SECONDS="${QEMU_TIMEOUT_SECONDS:-3}"
MONITOR_PORT=45453
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

. "${SCRIPT_DIR}/qemu_keyboard_common.sh"

if [ ! -f "$DISK_IMG" ]; then
    echo "FAIL: disk image not found: $DISK_IMG"
    exit 1
fi

if ! command -v qemu-system-i386 >/dev/null 2>&1; then
    echo "FAIL: qemu-system-i386 is not installed"
    exit 1
fi

LOG_FILE="build/qemu-kbd-t3-debug.log"
rm -f "$LOG_FILE"

timeout -k 1s "${TIMEOUT_SECONDS}s" qemu-system-i386 \
    -drive file="$DISK_IMG",format=raw,if=floppy \
    -display none \
    -monitor tcp:127.0.0.1:${MONITOR_PORT},server,nowait \
    -serial none \
    -debugcon file:"$LOG_FILE" \
    -global isa-debugcon.iobase=0xe9 \
    -no-reboot \
    -no-shutdown >/dev/null 2>&1 &
QEMU_PID=$!

send_key_when_ready "$LOG_FILE" "$MONITOR_PORT" 'KBD_SC_OK' || true
wait "$QEMU_PID" || true

if [ ! -f "$LOG_FILE" ]; then
    echo "FAIL: no QEMU debug output captured"
    exit 1
fi

if grep -q 'KBD_SC_OK' "$LOG_FILE"; then
    echo "PASS: keyboard scancode capture verified (KBD_SC_OK)"
    exit 0
fi

echo "FAIL: keyboard scancode marker KBD_SC_OK not detected"
cat "$LOG_FILE"
exit 1
