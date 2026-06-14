#!/bin/sh
DIR="$(dirname "$0")"
PLATFORM="${PLATFORM:-tg5040}"
SDCARD="/mnt/SDCARD"
LANDING_DIR="$SDCARD/LocalSend"
LOCALSEND="$DIR/bin/$PLATFORM/localsend"
LOGS_PATH="${LOGS_PATH:-/tmp}"
LOG="$LOGS_PATH/localsend.log"
DEVICE_NAME="TrimUI-Brick"
PID_FILE="/tmp/localsend_pak.pid"

LSPID=""

cleanup() {
    if [ -n "$LSPID" ]; then
        kill "$LSPID" 2>/dev/null
        LSPID=""
    fi
    rm -f "$PID_FILE"
    echo "$(date): Stopped." >> "$LOG"
}
trap cleanup EXIT

_find_tool() {
    name="$1"
    if command -v "$name" >/dev/null 2>&1; then
        command -v "$name"; return 0
    fi
    for d in \
        "/mnt/SDCARD/.system/$PLATFORM/bin" \
        "/usr/trimui/bin" \
        "/opt/trimui/bin" \
        "$DIR/../../.system/$PLATFORM/bin"; do
        [ -x "$d/$name" ] && { echo "$d/$name"; return 0; }
    done
    return 1
}

MINUI_PRESENTER=$(_find_tool minui-presenter 2>/dev/null)
MINUI_LIST=$(_find_tool minui-list 2>/dev/null)

echo "$(date): presenter=${MINUI_PRESENTER:-none} list=${MINUI_LIST:-none}" >> "$LOG"

show_message() {
    msg="$1"
    timeout="${2:-4}"
    if [ -n "$MINUI_PRESENTER" ]; then
        printf '%s' "$msg" | "$MINUI_PRESENTER" --stdin --timeout "$timeout"
    else
        echo "$msg" && sleep "$timeout"
    fi
}

mkdir -p "$LANDING_DIR"

if [ -f "$PID_FILE" ]; then
    old_pid=$(cat "$PID_FILE")
    kill "$old_pid" 2>/dev/null
    rm -f "$PID_FILE"
fi

if [ ! -x "$LOCALSEND" ]; then
    show_message "ERROR: localsend binary not found"
    exit 1
fi

echo "$(date): Starting LocalSend receiver -> $LANDING_DIR" >> "$LOG"

"$LOCALSEND" recv \
    --devname "$DEVICE_NAME" \
    --dir "$LANDING_DIR" \
    --https=false \
    >> "$LOG" 2>&1 &
LSPID=$!
echo "$LSPID" > "$PID_FILE"

sleep 2
if ! kill -0 "$LSPID" 2>/dev/null; then
    show_message "ERROR: LocalSend failed to start\nCheck: $LOG"
    exit 1
fi

if [ -n "$MINUI_LIST" ]; then
    printf 'Stop Receiver\n' | "$MINUI_LIST" \
        --title "LocalSend — send files to $DEVICE_NAME" \
        --stdin 2>/dev/null
elif [ -n "$MINUI_PRESENTER" ]; then
    printf 'LocalSend running\nDevice: %s\nSaving to: %s\n\nOpen LocalSend on your phone.\nPress any button to stop.' \
        "$DEVICE_NAME" "$LANDING_DIR" \
        | "$MINUI_PRESENTER" --stdin --timeout 3600
else
    while kill -0 "$LSPID" 2>/dev/null; do
        sleep 5 & wait $!
    done
fi
