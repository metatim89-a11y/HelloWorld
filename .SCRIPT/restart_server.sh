echo "=== [RESTART] ==="
bash ./.SCRIPT/stop_server.sh
sleep 1
bash ./.SCRIPT/start_server.sh
sleep 1
bash ./.SCRIPT/server_check.sh
echo "=== [DONE] ==="
