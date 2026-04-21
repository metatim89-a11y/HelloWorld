#!/data/data/com.termux/files/usr/bin/bash

FILE="index.js"

echo "🧩 Fixing initTicTacToe..."

# ONLY add if missing
grep -q "function initTicTacToe" "$FILE" || sed -i '/function initChessGame/a \

function initTicTacToe(){\
  return {\
    board: Array(9).fill(""),\
    turn: "X",\
    winner: null\
  };\
}\
' "$FILE"

echo "✅ initTicTacToe inserted"

echo "🔁 Restart server"
