#!/data/data/com.termux/files/usr/bin/bash

echo "=== [SERVER CHECK] ==="

# Find running node process for this project
PIDS=$(ps aux | grep "node .*index.js" | grep "$(pwd)" | grep -v grep | awk '{print $2}')

if [ -z "$PIDS" ]; then
  echo "[STATUS] ❌ OFFLINE"
  echo "=== [END] ==="
  exit 0
fi

IP=$(hostname -I 2>/dev/null | awk '{print $1}')
PORT=3000

for PID in $PIDS; do
  echo ""
  echo "[INFO] PID: $PID"
  echo "[INFO] PORT: $PORT"
  echo "[INFO] IP: ${IP:-127.0.0.1}"
  echo "[STATUS] ✅ RUNNING"
done

echo ""
echo "=== [END] ==="
