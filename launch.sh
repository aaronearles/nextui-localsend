#!/bin/sh
DIR="$(dirname "$0")"
PLATFORM="${PLATFORM:-tg5040}"
SDCARD="${SDCARD_PATH:-/mnt/SDCARD}"
LANDING_DIR="$SDCARD/LocalSend"
LOCALSEND="$DIR/bin/$PLATFORM/localsend"
LOG="${LOGS_PATH:+$LOGS_PATH/localsend.log}"
LOG="${LOG:-$SDCARD/LocalSend/localsend.log}"
DEVICE_NAME="TrimUI-Brick"
PID_FILE="/tmp/localsend_pak.pid"
LOGO="$SDCARD/.system/res/logo.png"

log() {
    mkdir -p "$(dirname "$LOG")" 2>/dev/null
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $*" >> "$LOG"
}

show_message() {
    msg="$1"
    timeout="${2:-3}"
    if command -v show2.elf >/dev/null 2>&1 && [ -f "$LOGO" ]; then
        show2.elf --mode=simple --image="$LOGO" --text="$msg" --timeout="$timeout"
    else
        echo "$msg" >&2
        sleep "$timeout"
    fi
}

mkdir -p "$LANDING_DIR"

# Toggle: if receiver is already running, stop it
if [ -f "$PID_FILE" ]; then
    old_pid=$(cat "$PID_FILE")
    if kill -0 "$old_pid" 2>/dev/null; then
        log "Stopping receiver (PID $old_pid)"
        kill "$old_pid" 2>/dev/null
        rm -f "$PID_FILE"
        log "Stopped."
        show_message "LocalSend stopped" 3
        exit 0
    fi
    rm -f "$PID_FILE"
fi

# Start receiver
if [ ! -x "$LOCALSEND" ]; then
    show_message "ERROR: localsend binary not found" 4
    exit 1
fi

log "Starting receiver -> $LANDING_DIR"

"$LOCALSEND" recv \
    --devname "$DEVICE_NAME" \
    --dir "$LANDING_DIR" \
    >> "$LOG" 2>&1 &
LSPID=$!
echo "$LSPID" > "$PID_FILE"

sleep 2
if ! kill -0 "$LSPID" 2>/dev/null; then
    rm -f "$PID_FILE"
    log "Failed to start"
    show_message "LocalSend failed to start" 4
    exit 1
fi

log "Started (PID $LSPID)"
show_message "LocalSend started. Send files to $DEVICE_NAME. Launch again to stop." 5
exit 0
