#!/data/data/com.termux/files/usr/bin/bash

echo "=== [STOP] Server Shutdown ==="

# Kill ALL node processes running index.js
PIDS=$(pkill -f index.js)

if [ $? -eq 0 ]; then
  echo "[SUCCESS] Server stopped"
else
  echo "[INFO] No server running"
fi

echo "=== [END] ==="
