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

mkdir -p "$LANDING_DIR"

# Kill any previously orphaned instance
if [ -f "$PID_FILE" ]; then
    old_pid=$(cat "$PID_FILE")
    kill "$old_pid" 2>/dev/null
    rm -f "$PID_FILE"
fi

echo "$(date): Starting LocalSend receiver -> $LANDING_DIR" >> "$LOG"

# Start receiver in background
"$LOCALSEND" recv \
    --devname "$DEVICE_NAME" \
    --dir "$LANDING_DIR" \
    --https=false \
    >> "$LOG" 2>&1 &

LSPID=$!
echo "$LSPID" > "$PID_FILE"

# Show status on screen and block until user exits
# NextUI will display output from this script and return on any button press
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

# Wait for NextUI to kill us (button press returns from the pak)
# or wait indefinitely — NextUI handles the exit signal
wait "$LSPID" 2>/dev/null

# Cleanup on exit
kill "$LSPID" 2>/dev/null
rm -f "$PID_FILE"
echo "$(date): Stopped." >> "$LOG"
