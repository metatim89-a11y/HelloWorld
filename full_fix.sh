#!/data/data/com.termux/files/usr/bin/bash

echo "🔥 Applying CLEAN FIX..."

mkdir -p public/css

# ===== index.js =====
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

const users = {
  RobV: { password: "RobV" },
  TimM: { password: "TimM" }
};

let rooms = {};

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
    turn: "white",
    mode: "ai"
  };
}

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

io.on('connection', (socket)=>{

  socket.on("joinRoom", ({roomId, username})=>{
    socket.join(roomId);
    socket.roomId = roomId;

    if (!rooms[roomId]) {
      rooms[roomId] = { chess: initChessGame() };
    }

    io.to(roomId).emit("roomData", rooms[roomId]);

    socket.emit("update", {
      gameType:"chess",
      game: rooms[roomId].chess
    });
  });

  socket.on("chat", msg=>{
    io.emit("chat", msg);
  });

  socket.on("move", ({gameType, move, player})=>{
    let game = rooms[socket.roomId]?.[gameType];
    if (!game) return;

    game.board[move.to] = game.board[move.from];
    game.board[move.from] = "";
    game.turn = game.turn==="white"?"black":"white";

    io.to(socket.roomId).emit("update",{gameType,game});
  });

});

app.use(express.static(path.join(__dirname,'public')));
server.listen(PORT,()=>console.log("Server running "+PORT));
JS

# ===== index.html =====
cat > public/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
<title>Platform</title>
<link rel="stylesheet" href="/css/styles.css">
</head>
<body>

<div id="nav">
  <button onclick="openPage('home')">Home</button>
  <button onclick="openPage('chess')">Chess</button>
  <button onclick="openPage('chat')">Chat</button>
  <button onclick="openPage('profile')">Profile</button>
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

<div class="page" id="chess">
<div class="card">
<h2>Chess</h2>
<div id="board"></div>
</div>
</div>

<div class="page" id="chat">
<div class="card">
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

let board=[],player="white",myName="",roomId="room1",selected=null;

function openPage(id){
 document.querySelectorAll(".page").forEach(p=>p.classList.remove("active"));
 document.getElementById(id).classList.add("active");
 if(id==="profile") loadProfile();
}

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
 });
}

function visitor(){
 myName="Visitor_"+Math.floor(Math.random()*9999);
 socket.emit("joinRoom",{roomId,username:myName});
}

function draw(){
  let html = "";
  board.forEach((p,i)=>{
    html += `<button onclick="clickCell(${i})">${p || "."}</button>`;
    if((i+1)%8===0) html += "<br>";
  });
  document.getElementById("board").innerHTML = html;
}

function clickCell(i){
 if(selected===null){
  selected=i;
 } else {
  socket.emit("move",{gameType:"chess",move:{from:selected,to:i},player});
  selected=null;
 }
}

socket.on("roomData",r=>{
 board=r.chess.board;
 player=r.chess.turn;
 draw();
});

socket.on("update",({gameType,game})=>{
 if(gameType==="chess"){
  board=game.board;
  player=game.turn;
  draw();
 }
});

function sendChat(){
 let m=document.getElementById("msg").value;
 socket.emit("chat",{user:myName,msg:m});
}

socket.on("chat",d=>{
 document.getElementById("chatBox").innerHTML += `<div>${d.user}: ${d.msg}</div>`;
});

function loadProfile(){
 fetch("/api/profile")
 .then(r=>r.json())
 .then(d=>{
  document.getElementById("profileData").innerHTML =
    "User: " + (d.name || "guest");
 });
}
</script>

</body>
</html>
HTML

# ===== styles.css =====
cat > public/css/styles.css << 'CSS'
body {
  margin:0;
  font-family:sans-serif;
  background:linear-gradient(135deg,#1e1e2f,#12121a);
  color:white;
}

#nav {
  display:flex;
  gap:10px;
  padding:10px;
}

.page { display:none; }
.page.active { display:block; }

.card {
  margin:20px;
  padding:15px;
  border-radius:12px;
  background:rgba(255,255,255,0.08);
}

button {
  margin:2px;
  padding:8px;
  border:none;
  border-radius:6px;
  cursor:pointer;
}

#board button {
  width:40px;
  height:40px;
}
CSS

echo "✅ FIX COMPLETE"
