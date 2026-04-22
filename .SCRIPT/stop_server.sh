#!/data/data/com.termux/files/usr/bin/bash

echo "=== [STOP] Server Shutdown ==="

# Kill ALL node processes running index.js
pkill -f index.js
pkill -f llama-server

if [ $? -eq 0 ]; then
  echo "[SUCCESS] Server and AI stopped"
else
  echo "[INFO] No server running"
fi

echo "=== [END] ==="
