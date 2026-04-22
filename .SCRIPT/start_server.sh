#!/data/data/com.termux/files/usr/bin/bash

echo "=== [START] ==="

mkdir -p ./.LOGS

# 🔥 AUTO LOG BEFORE START
bash ./.SCRIPT/auto_log.sh

pkill -f index.js 2>/dev/null
pkill -f llama-server 2>/dev/null

nohup node ./index.js >> ./server.log 2>> ./.LOGS/error.log &

sleep 2

echo "[DONE]"
