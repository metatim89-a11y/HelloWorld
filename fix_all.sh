#!/data/data/com.termux/files/usr/bin/bash

echo "🔧 Fixing frontend..."

FILE="public/index.html"

# ===== FULL SAFE REWRITE (avoids broken JS issues) =====
cat > "$FILE" << 'HTML'
<!DOCTYPE html>
<html>
<head>
  <title>Game Platform</title>
  <link rel="stylesheet" href="/css/styles.css">
</head>
<body>

<div class="card">
  <h2>Login</h2>
  <input id="user" placeholder="RobV or TimM">
  <button onclick="login()">Login</button>
  <button onclick="visitor()">Play as Visitor</button>
</div>

<div class="card">
  <h2>Chess</h2>
  <button onclick="setMode('ai')">AI</button>
  <button onclick="setMode('multi')">Multiplayer</button>
  <div id="board"></div>
</div>

<script src="/socket.io/socket.io.js"></script>
<script>

const socket = io();
let board = [];
let player = "white";
let myName = "";
let roomId = "room1";
let selected = null;

function login(){
  myName = document.getElementById("user").value;

  fetch("/login",{
    method:"POST",
    headers:{"Content-Type":"application/json"},
    body:JSON.stringify({username:myName})
  })
  .then(res => res.json())
  .then(data => {
    if (!data.success) {
      alert("Login failed");
      return;
    }
    socket.emit("joinRoom",{roomId,username:myName});
  })
  .catch(err => {
    console.error(err);
    alert("Server error");
  });
}

function visitor(){
  myName = "Visitor_" + Math.floor(Math.random()*10000);
  socket.emit("joinRoom",{roomId,username:myName});
}

function draw(){
  let html="";
  board.forEach((p,i)=>{
    html += `<button onclick="clickCell(${i})">${p||"."}</button>`;
    if((i+1)%8===0) html+="<br>";
  });
  document.getElementById("board").innerHTML=html;
}

function clickCell(i){
  if(selected===null){
    selected=i;
  } else {
    socket.emit("move",{
      gameType:"chess",
      move:{from:selected,to:i},
      player
    });
    selected=null;
  }
}

socket.on("update", ({gameType,game})=>{
  if(gameType==="chess"){
    board = game.board;
    player = game.turn;
    draw();
  }
});

function setMode(mode){
  socket.emit("setMode",mode);
}

</script>

</body>
</html>
HTML

echo "✅ index.html fixed"

echo "🚀 Done. Restart server:"
echo "node index.js"
