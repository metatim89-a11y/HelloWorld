#!/data/data/com.termux/files/usr/bin/bash

echo "🎮 Adding TicTacToe (safe patch)..."

# =========================
# 1. PATCH SERVER (index.js)
# =========================

FILE="index.js"

# add initTicTacToe if missing
grep -q "initTicTacToe" "$FILE" || sed -i '/function initChessGame/a \
\
function initTicTacToe(){\
  return {\
    board: Array(9).fill(""),\
    turn: "X",\
    winner: null\
  };\
}\
' "$FILE"

echo "✅ initTicTacToe ensured"

# add tictactoe to room init
sed -i 's/chess: initChessGame()/chess: initChessGame(),\
      tictactoe: initTicTacToe()/g' "$FILE"

echo "✅ room init updated"

# patch move handler (append TTT logic safely)
grep -q "gameType === \"tictactoe\"" "$FILE" || sed -i '/socket.on("move"/a \
\
    if(gameType === "tictactoe"){\
      if(game.board[move.index] || game.winner) return;\
      game.board[move.index] = game.turn;\
\
      const wins=[[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];\
      for(let w of wins){\
        if(w.every(i=>game.board[i]===game.turn)){\
          game.winner = game.turn;\
        }\
      }\
\
      game.turn = game.turn==="X"?"O":"X";\
    }\
' "$FILE"

echo "✅ move handler patched"

# =========================
# 2. PATCH FRONTEND
# =========================

HTML="public/index.html"

# add loadGame ttt support
grep -q 'tictactoe' "$HTML" || sed -i '/function loadGame/a \
  else if(name==="tictactoe"){\
    document.getElementById("gameContainer").innerHTML = "<div id=\\"ttt\\"></div>";\
    drawTTT();\
  }\
' "$HTML"

echo "✅ loadGame updated"

# add TTT JS if missing
grep -q "drawTTT" "$HTML" || sed -i '/let board/a \
let tttBoard = [];\
\
function drawTTT(){\
  let html="";\
  tttBoard.forEach((v,i)=>{\
    html += `<button onclick="clickTTT(${i})">${v||"."}</button>`;\
    if((i+1)%3===0) html+="<br>";\
  });\
  document.getElementById("ttt").innerHTML = html;\
}\
\
function clickTTT(i){\
  socket.emit("move",{gameType:"tictactoe",move:{index:i}});\
}\
' "$HTML"

echo "✅ TTT UI added"

# update socket handler
grep -q 'gameType==="tictactoe"' "$HTML" || sed -i '/socket.on("update"/a \
  if(gameType==="tictactoe"){\
    tttBoard = game.board;\
    drawTTT();\
    if(game.winner){ alert("Winner: "+game.winner); }\
  }\
' "$HTML"

echo "✅ socket update patched"

echo "🔥 DONE — restart server"
