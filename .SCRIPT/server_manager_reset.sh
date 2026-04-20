# File: ./.SCRIPT/server_manager_reset.sh
# Version: 2.000
# Purpose: Clean old server scripts + rebuild fresh system

echo "=== [RESET] Cleaning old server system ==="

# Ensure base dirs exist
mkdir -p ./.SCRIPT ./.LOGS

# Remove old scripts
rm -f ./.SCRIPT/start_server.sh
rm -f ./.SCRIPT/stop_server.sh
rm -f ./.SCRIPT/server_check.sh
rm -f ./.SCRIPT/restart_server.sh

# Remove stale PID + logs
rm -f ./.LOGS/server.pid
rm -f ./.LOGS/*.err

echo "[CLEAN] Old scripts and logs removed"

########################################
# START SERVER
########################################
cat << 'INNER' > ./.SCRIPT/start_server.sh
PID_FILE="./.LOGS/server.pid"
LOG_FILE="./.LOGS/start_server.err"

echo "=== [START] Server Startup ==="

mkdir -p ./.LOGS

if [ -f "$PID_FILE" ]; then
  PID=$(cat "$PID_FILE")
  if ps -p $PID > /dev/null 2>&1; then
    echo "[INFO] Already running (PID: $PID)"
    exit 0
  fi
fi

echo "[ACTION] Starting server..."
node ./index.js > ./server.log 2>> "$LOG_FILE" &
PID=$!

echo $PID > "$PID_FILE"

sleep 1

if ps -p $PID > /dev/null 2>&1; then
  echo "[SUCCESS] Started (PID: $PID)"
else
  echo "[ERROR] Failed to start"
fi

echo "=== [END] ==="
INNER
chmod +x ./.SCRIPT/start_server.sh

########################################
# STOP SERVER
########################################
cat << 'INNER' > ./.SCRIPT/stop_server.sh
PID_FILE="./.LOGS/server.pid"

echo "=== [STOP] Server Shutdown ==="

if [ ! -f "$PID_FILE" ]; then
  echo "[INFO] No PID file"
  exit 0
fi

PID=$(cat "$PID_FILE")

if ps -p $PID > /dev/null 2>&1; then
  echo "[ACTION] Killing $PID"
  kill $PID
  rm -f "$PID_FILE"
  echo "[SUCCESS] Stopped"
else
  echo "[INFO] Already dead"
  rm -f "$PID_FILE"
fi

echo "=== [END] ==="
INNER
chmod +x ./.SCRIPT/stop_server.sh

########################################
# SERVER CHECK
########################################
cat << 'INNER' > ./.SCRIPT/server_check.sh
PID_FILE="./.LOGS/server.pid"

echo "=== [SERVER CHECK] ==="

if [ ! -f "$PID_FILE" ]; then
  echo "[STATUS] ❌ Not started"
  exit 0
fi

PID=$(cat "$PID_FILE")

if ps -p $PID > /dev/null 2>&1; then
  PORT=$(lsof -Pan -p "$PID" -i 2>/dev/null | grep LISTEN | awk '{print $9}' | sed 's/.*://')
  echo "[INFO] PID: $PID"
  echo "[INFO] Port: ${PORT:-3000}"
  echo "[STATUS] ✅ RUNNING"
else
  echo "[STATUS] ❌ Stale PID"
fi

echo "=== [END] ==="
INNER
chmod +x ./.SCRIPT/server_check.sh

########################################
# RESTART SERVER
########################################
cat << 'INNER' > ./.SCRIPT/restart_server.sh
echo "=== [RESTART] ==="
bash ./.SCRIPT/stop_server.sh
sleep 1
bash ./.SCRIPT/start_server.sh
sleep 1
bash ./.SCRIPT/server_check.sh
echo "=== [DONE] ==="
INNER
chmod +x ./.SCRIPT/restart_server.sh

echo "=== [COMPLETE] Clean rebuild finished ==="
