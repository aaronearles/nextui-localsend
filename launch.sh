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
trap cleanup INT TERM EXIT

mkdir -p "$LANDING_DIR"

# Kill any previously orphaned instance
if [ -f "$PID_FILE" ]; then
    old_pid=$(cat "$PID_FILE")
    kill "$old_pid" 2>/dev/null
    rm -f "$PID_FILE"
fi

if [ ! -x "$LOCALSEND" ]; then
    echo ""
    echo "  ERROR: binary not found"
    echo "  $LOCALSEND"
    echo ""
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

# Brief pause to catch immediate crashes (e.g. port already in use)
sleep 1
if ! kill -0 "$LSPID" 2>/dev/null; then
    echo ""
    echo "  ERROR: LocalSend failed to start."
    echo "  Check log: $LOG"
    echo ""
    exit 1
fi

echo ""
echo "  LocalSend is running"
echo ""
echo "  Device name : $DEVICE_NAME"
echo "  Saving to   : $LANDING_DIR"
echo ""
echo "  Open LocalSend on your phone"
echo "  and send files to this device."
echo ""
echo "  Press any button to stop."
echo ""

wait "$LSPID"
