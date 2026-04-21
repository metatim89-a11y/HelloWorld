#!/bin/bash

echo "[1] Starting app with nodemon..."
nodemon index.js &
APP_PID=$!

sleep 3

echo "[2] Starting ngrok tunnel on port 3000..."
ngrok http 3000

echo "[INFO] App PID: $APP_PID"
