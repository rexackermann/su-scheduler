#!/system/bin/sh
# ---------------------------------------------------------------------------------------
# 🏁 Su Scheduler Boot Service (service.sh) 🏁
# ---------------------------------------------------------------------------------------
# Author: Rex Ackermann
# Description: This code wakes up when the system finishes booting.
# It acts as the "Starter Motor" for the main daemon.
# ---------------------------------------------------------------------------------------

# 📍 Identify where we are in the module directory
MODDIR=${0%/*}

# 📂 Define our diagnostics paths
DATA_DIR="/data/adb/su-scheduler"
LOG_FILE="$DATA_DIR/events.log"

# 🏗️ Ensure our workspace exists (it should, but safety first!)
[ ! -d "$DATA_DIR" ] && mkdir -p "$DATA_DIR"

# 📝 Log the awakening of the service
echo "$(date "+%Y-%m-%d %H:%M:%S") - [Service] 🛌 Waking up... System boot detected." >> "$LOG_FILE"

# ⏳ [Phase 1] The Decryption Watch
# We wait for the internal storage to be decrypted (FBE unlock).
# This is verified by the presence of /sdcard/Android.
# We check every 10 seconds indefinitely until ready.
while true; do
    if [ -d "/sdcard/Android" ]; then
        echo "$(date "+%Y-%m-%d %H:%M:%S") - [Service] 🔓 Storage decrypted! Proceeding..." >> "$LOG_FILE"
        break
    fi
    sleep 10
done

# A small extra pause for the system to settle
sleep 5

# 🚀 [Phase 2] The Ignition
# We try to start the daemon from the system path (magic mounted) first.
# 🎯 Determine the correct binary path
if [ -f "/system/bin/su-schedulerd" ]; then
    DAEMON="/system/bin/su-schedulerd"
elif [ -f "$MODDIR/system/bin/su-schedulerd" ]; then
    DAEMON="$MODDIR/system/bin/su-schedulerd"
    chmod +x "$DAEMON"
else
    echo "$(date "+%Y-%m-%d %H:%M:%S") - [Service] ❌ CRITICAL: The engine binary is MISSING!" >> "$LOG_FILE"
    exit 1
fi

LOCK_FILE="/dev/.su_scheduler.lock"

# 🔄 [Phase 2] The Watchdog Loop
# Keep the daemon alive forever.
(
    while true; do
        IS_ALIVE=0
        
        # Check if running via lockfile
        if [ -f "$LOCK_FILE" ]; then
            PID=$(cat "$LOCK_FILE")
            if [ -n "$PID" ] && [ -d "/proc/$PID" ]; then
                IS_ALIVE=1
            fi
        fi
        
        if [ $IS_ALIVE -eq 0 ]; then
            echo "$(date "+%Y-%m-%d %H:%M:%S") - [Service] ⚠️ Daemon not running. (Re)starting..." >> "$LOG_FILE"
            # Cleanup stale lock
            rm -f "$LOCK_FILE"
            # Start daemon (it now handles boot tasks automatically on startup)
            nohup "$DAEMON" >/dev/null 2>&1 &
        fi
        
        # Sleep for a minute before checking again
        sleep 60
    done
) &

echo "$(date "+%Y-%m-%d %H:%M:%S") - [Service] ✅ Handover complete. Closing service script." >> "$LOG_FILE"
