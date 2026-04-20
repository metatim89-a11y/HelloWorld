# File: ./.SCRIPT/status_server.sh
# Version: 0.001
# Purpose: Check server status

SCRIPT_NAME="status_server.sh"

echo "=== [STATUS] Server Check ==="

PID=$(pgrep -f "node index.js")

if [ -z "$PID" ]; then
  echo "[STATUS] Server is OFFLINE"
else
  echo "[STATUS] Server is RUNNING (PID: $PID)"
fi

echo "=== [END] ==="
