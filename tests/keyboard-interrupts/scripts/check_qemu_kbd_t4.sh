#!/usr/bin/env bash
set -eu

DISK_IMG="${1:-build/disk-kbd.img}"
TIMEOUT_SECONDS="${QEMU_TIMEOUT_SECONDS:-3}"
MONITOR_PORT=45454

if [ ! -f "$DISK_IMG" ]; then
    echo "FAIL: disk image not found: $DISK_IMG"
    exit 1
fi

if ! command -v qemu-system-i386 >/dev/null 2>&1; then
    echo "FAIL: qemu-system-i386 is not installed"
    exit 1
fi

LOG_FILE="build/qemu-kbd-t4-debug.log"
rm -f "$LOG_FILE"

send_key() {
    local attempt

    for attempt in 1 2 3 4 5; do
        if bash -c "exec 3<>/dev/tcp/127.0.0.1/${MONITOR_PORT}; printf 'sendkey a\r\n' >&3; exec 3>&-; exec 3<&-" >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
    done

    return 1
}

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

sleep 1
send_key || true
wait "$QEMU_PID" || true

if [ ! -f "$LOG_FILE" ]; then
    echo "FAIL: no QEMU debug output captured"
    exit 1
fi

if ! grep -q 'KBD_IRQ1_OK' "$LOG_FILE"; then
    echo "FAIL: keyboard IRQ path not functional (KBD_IRQ1_OK missing)"
    cat "$LOG_FILE"
    exit 1
fi

if ! grep -q 'HI_TICKS_3' "$LOG_FILE"; then
    echo "FAIL: timer coexistence not verified (HI_TICKS_3 missing)"
    cat "$LOG_FILE"
    exit 1
fi

if grep -qE 'IX_00|IX_06|IX_13' "$LOG_FILE"; then
    echo "FAIL: unexpected exception marker detected during keyboard/timer coexistence"
    cat "$LOG_FILE"
    exit 1
fi

echo "PASS: keyboard IRQ and timer coexistence verified"
exit 0
