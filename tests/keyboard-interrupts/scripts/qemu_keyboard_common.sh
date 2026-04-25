#!/usr/bin/env bash

wait_for_log_marker() {
    local log_file="$1"
    local marker="$2"
    local max_attempts="$3"
    local delay_seconds="$4"
    local attempt

    for attempt in $(seq 1 "$max_attempts"); do
        if [ -f "$log_file" ] && grep -q "$marker" "$log_file"; then
            return 0
        fi
        sleep "$delay_seconds"
    done

    return 1
}

send_monitor_command() {
    local monitor_port="$1"
    local command_text="$2"

    bash -c "exec 3<>/dev/tcp/127.0.0.1/${monitor_port}; printf '%s\r\n' '${command_text}' >&3; exec 3>&-; exec 3<&-" >/dev/null 2>&1
}

wait_for_keyboard_ready() {
    local log_file="$1"

    wait_for_log_marker "$log_file" 'KBD_INIT_OK' 30 0.1 &&
        wait_for_log_marker "$log_file" 'HI_TICKS_3' 40 0.1
}

send_key_when_ready() {
    local log_file="$1"
    local monitor_port="$2"
    local expected_marker="$3"
    local attempt

    if ! wait_for_keyboard_ready "$log_file"; then
        return 1
    fi

    for attempt in 1 2 3; do
        if send_monitor_command "$monitor_port" 'sendkey a'; then
            if wait_for_log_marker "$log_file" "$expected_marker" 10 0.1; then
                return 0
            fi
        fi
        sleep 0.2
    done

    return 1
}
