#!/data/data/com.termux/files/usr/bin/bash

echo "🧹 Rebuilding clean working version..."

# =========================
# INDEX.JS
# =========================
cat > index.js << 'JS'
const express = require('express');
const session = require('express-session');
const path = require('path');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = new Server(server);

const PORT = 3000;

app.use(express.json());
app.use(session({
  secret: 'dev-secret-key',
  resave: false,
  saveUninitialized: false
}));

// ===== USERS =====
const users = {
  RobV: { password: "RobV" },
  TimM: { password: "TimM" }
};

let onlineUsers = {};
let rooms = {};

// ===== GAMES =====
function initChessGame() {
  return {
    board: [
      "r","n","b","q","k","b","n","r",
      "p","p","p","p","p","p","p","p",
      "","","","","","","","",
      "","","","","","","","",
      "","","","","","","","",
      "","","","","","","","",
      "P","P","P","P","P","P","P","P",
      "R","N","B","Q","K","B","N","R"
    ],
    turn: "white"
  };
}

function initTicTacToe(){
  return {
    board: Array(9).fill(""),
    turn: "X",
    winner: null
  };
}

// ===== AUTH =====
app.post('/login', (req,res)=>{
  const { username, password } = req.body;
  if (!users[username] || users[username].password !== password) {
    return res.json({ success:false });
  }
  req.session.user = { name: username };
  res.json({ success:true });
});

app.get('/api/profile',(req,res)=>{
  if(!req.session.user) return res.status(401).json({});
  res.json(req.session.user);
});

// ===== SOCKET =====
io.on('connection', (socket)=>{

  socket.on("disconnect", ()=>{
    if(socket.username){
      delete onlineUsers[socket.username];
      io.emit("userList", { online:Object.keys(onlineUsers), all:Object.keys(users) });
    }
  });

  socket.on("joinRoom", ({roomId, username})=>{
    socket.username = username;
    onlineUsers[username] = true;

    io.emit("userList", {
      online:Object.keys(onlineUsers),
      all:Object.keys(users)
    });

    socket.join(roomId);
    socket.roomId = roomId;

    if (!rooms[roomId]) {
      rooms[roomId] = {
        chess: initChessGame(),
        tictactoe: initTicTacToe()
      };
    }

    io.to(roomId).emit("roomData", rooms[roomId]);

    socket.emit("update", { gameType:"chess", game:rooms[roomId].chess });
    socket.emit("update", { gameType:"tictactoe", game:rooms[roomId].tictactoe });
  });

  socket.on("chat", msg=>{
    io.emit("chat", msg);
  });

  socket.on("move", ({gameType, move, player})=>{
    let game = rooms[socket.roomId]?.[gameType];
    if (!game) return;

    // ===== TTT =====
    if(gameType==="tictactoe"){
      if(game.board[move.index] || game.winner) return;

      game.board[move.index] = game.turn;

      const wins=[[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];
      for(let w of wins){
        if(w.every(i=>game.board[i]===game.turn)){
          game.winner = game.turn;
        }
      }

      game.turn = game.turn==="X"?"O":"X";
    }

    // ===== CHESS (simple) =====
    if(gameType==="chess"){
      if (!game.board[move.from]) return;
      game.board[move.to] = game.board[move.from];
      game.board[move.from] = "";
      game.turn = game.turn==="white"?"black":"white";
    }

    io.to(socket.roomId).emit("update",{gameType,game});
  });

});

app.use(express.static(path.join(__dirname,'public')));
server.listen(PORT,()=>console.log("Server running "+PORT));
JS

# =========================
# INDEX.HTML
# =========================
cat > public/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
<title>Platform</title>
<link rel="stylesheet" href="/css/styles.css">
</head>
<body class="theme-dark">

<div id="nav">
  <button onclick="openPage('home')">Home</button>
  <button onclick="openPage('games')">Games</button>
  <button onclick="openPage('chat')">Chat</button>
  <button onclick="openPage('profile')">Profile</button>

  <button onclick="setTheme('dark')">Dark</button>
  <button onclick="setTheme('light')">Light</button>
  <button onclick="setTheme('neon')">Neon</button>
</div>

<div id="pages">

<div class="page active" id="home">
<div class="card">
<input id="user" placeholder="user">
<input id="pass" placeholder="pass">
<button onclick="login()">Login</button>
<button onclick="visitor()">Visitor</button>
</div>
</div>

<div class="page" id="games">
<div class="card">
<h2>Games</h2>
<button onclick="loadGame('chess')">Chess</button>
<button onclick="loadGame('tictactoe')">TicTacToe</button>
<div id="gameContainer"></div>
</div>
</div>

<div class="page" id="chat">
<div class="card">
<div id="users"></div>
<div id="chatBox"></div>
<input id="msg">
<button onclick="sendChat()">Send</button>
</div>
</div>

<div class="page" id="profile">
<div class="card" id="profileData"></div>
</div>

</div>

<script src="/socket.io/socket.io.js"></script>
<script>
const socket = io();

let board=[], tttBoard=[], player="white", myName="", roomId="room1", selected=null;

// NAV
function openPage(id){
 document.querySelectorAll(".page").forEach(p=>p.classList.remove("active"));
 document.getElementById(id).classList.add("active");
 if(id==="profile") loadProfile();
}

// LOGIN
function login(){
 myName=document.getElementById("user").value;
 let password=document.getElementById("pass").value;

 fetch("/login",{
  method:"POST",
  headers:{"Content-Type":"application/json"},
  body:JSON.stringify({username:myName,password})
 })
 .then(r=>r.json())
 .then(d=>{
  if(!d.success) return alert("Login failed");
  socket.emit("joinRoom",{roomId,username:myName});
  openPage("games");
 });
}

function visitor(){
 myName="Visitor_"+Math.floor(Math.random()*9999);
 socket.emit("joinRoom",{roomId,username:myName});
 openPage("games");
}

// GAMES
function loadGame(name){
 if(name==="chess"){
  document.getElementById("gameContainer").innerHTML="<div id='board'></div>";
  draw();
 }
 if(name==="tictactoe"){
  document.getElementById("gameContainer").innerHTML="<div id='ttt'></div>";
  drawTTT();
 }
}

// CHESS
function draw(){
 let html="";
 board.forEach((p,i)=>{
  html+=`<button onclick="clickCell(${i})">${p||"."}</button>`;
  if((i+1)%8===0) html+="<br>";
 });
 document.getElementById("board").innerHTML=html;
}

function clickCell(i){
 if(selected===null){ selected=i; }
 else{
  socket.emit("move",{gameType:"chess",move:{from:selected,to:i},player});
  selected=null;
 }
}

// TTT
function drawTTT(){
 let html="";
 tttBoard.forEach((v,i)=>{
  html+=`<button onclick="clickTTT(${i})">${v||"."}</button>`;
  if((i+1)%3===0) html+="<br>";
 });
 document.getElementById("ttt").innerHTML=html;
}

function clickTTT(i){
 socket.emit("move",{gameType:"tictactoe",move:{index:i}});
}

// SOCKET
socket.on("update", ({gameType,game})=>{
 if(gameType==="chess"){
  board=game.board;
  draw();
 }
 if(gameType==="tictactoe"){
  tttBoard=game.board;
  drawTTT();
  if(game.winner) alert("Winner: "+game.winner);
 }
});

socket.on("userList", data=>{
 let html="";
 data.all.forEach(u=>{
  let online=data.online.includes(u);
  html+=`<div style="color:${online?'lime':'gray'}">${u}</div>`;
 });
 document.getElementById("users").innerHTML=html;
});

// CHAT
function sendChat(){
 let m=document.getElementById("msg").value;
 socket.emit("chat",{user:myName,msg:m});
}

socket.on("chat",d=>{
 document.getElementById("chatBox").innerHTML+=`<div>${d.user}: ${d.msg}</div>`;
});

// PROFILE
function loadProfile(){
 fetch("/api/profile")
 .then(r=>r.json())
 .then(d=>{
  document.getElementById("profileData").innerText="User: "+(d.name||"guest");
 });
}

// THEMES
function setTheme(t){
 document.body.className="theme-"+t;
}
</script>

</body>
</html>
HTML

echo "✅ CLEAN BUILD DONE"
echo "🚀 Restart: pkill node && node index.js"
