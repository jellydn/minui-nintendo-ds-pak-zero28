#!/bin/sh

# Safe defaults for unset MinUI vars
: "${LOGS_PATH:=/tmp}"
: "${SDCARD_PATH:=/mnt/SDCARD}"
: "${PLATFORM:=tg5040}"

rm -f "$LOGS_PATH/NDS.txt"
exec >>"$LOGS_PATH/NDS.txt" 2>&1

echo "$0" "$@"

NDS_DIR="$SDCARD_PATH/Emus/$PLATFORM/NDS.pak"
DRESTIC_DIR="$NDS_DIR/drastic"

export HOME="$DRESTIC_DIR"
export PATH="$DRESTIC_DIR:$PATH"
export LD_LIBRARY_PATH="$DRESTIC_DIR/libs:$LD_LIBRARY_PATH"

# Keep screen awake while emulator runs
echo "1" >/tmp/stay_awake

# Background sync loop (stops device from sleeping on menu access)
while :; do
    syncsettings.elf 2>/dev/null
done &
LOOP_PID=$!

# Run the emulator
cd "$DRESTIC_DIR" || exit 1
./drastic64 "$1"

# Cleanup
sync
kill "$LOOP_PID" 2>/dev/null
rm -f /tmp/stay_awake
