#!/data/data/com.termux/files/usr/bin/bash

echo "=== [REBUILD] ==="

rm -rf ./.LOGS
mkdir -p ./.LOGS

# 🔥 AUTO LOG AFTER CLEAN
bash ./.SCRIPT/auto_log.sh

echo "[DONE]"
