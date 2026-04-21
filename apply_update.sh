#!/data/data/com.termux/files/usr/bin/bash

echo "🔥 Applying FULL PROJECT UPDATE..."

mkdir -p public/css

# ================= SERVER =================
cat > index.js << 'JS'
const express = require('express');
const session = require('express-session');
const path = require('path');
const http = require('http');
const { Server } = require('socket.io');
const fs = require('fs');

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
  RobV: { password: "RobV", role: "admin" },
  TimM: { password: "TimM", role: "user" }
};

// ===== ROOMS =====
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

// ===== AUTH =====
app.post('/login', (req,res)=>{
  const { username, password } = req.body;

  if (!users[username] || users[username].password !== password) {
    return res.json({ success:false });
  }

  req.session.user = { name: username, role: users[username].role };
  res.json({ success:true });
});

app.post('/register', (req,res)=>{
  const { username, password } = req.body;

  if (users[username]) return res.json({ success:false });

  users[username] = { password, role:"user" };
  res.json({ success:true });
});

app.get('/api/profile', (req,res)=>{
  if (!req.session.user) return res.status(401).json({ error:"Not logged in" });
  res.json(req.session.user);
});

// ===== SOCKET =====
io.on('connection', (socket)=>{

  socket.on("joinRoom", ({roomId, username})=>{
    socket.join(roomId);
    socket.roomId = roomId;

    if (!rooms[roomId]) {
      rooms[roomId] = { chess: initChessGame() };
    }

    io.to(roomId).emit("roomData", rooms[roomId]);

    // FIX: send board instantly
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

    if (!validateMove(game, move, player)) return;

    applyMove(game, move);

    if (game.mode==="ai" && game.turn==="black") {
      let ai = getAIMove(game.board);
      if (ai) applyMove(game, ai);
    }

    io.to(socket.roomId).emit("update",{gameType,game});
  });

});

// ===== CHESS VALIDATION =====
function validateMove(game, move, player){
  const piece = game.board[move.from];
  if (!piece) return false;

  const isWhite = piece === piece.toUpperCase();
  if ((isWhite && player!=="white") || (!isWhite && player!=="black")) return false;

  const fromRow = Math.floor(move.from/8);
  const toRow = Math.floor(move.to/8);
  const fromCol = move.from%8;
  const toCol = move.to%8;

  const dRow = toRow - fromRow;
  const dCol = toCol - fromCol;

  const type = piece.toLowerCase();

  if(type==="p"){
    const dir = isWhite?-1:1;
    if(dCol===0 && !game.board[move.to]){
      if(dRow===dir) return true;
    }
    if(Math.abs(dCol)===1 && dRow===dir && game.board[move.to]) return true;
    return false;
  }

  if(type==="n"){
    return (Math.abs(dRow)===2 && Math.abs(dCol)===1) ||
           (Math.abs(dRow)===1 && Math.abs(dCol)===2);
  }

  if(type==="k"){
    return Math.abs(dRow)<=1 && Math.abs(dCol)<=1;
  }

  return true;
}

// ===== APPLY MOVE =====
function applyMove(game, move){
  game.board[move.to] = game.board[move.from];
  game.board[move.from] = "";
  game.turn = game.turn==="white"?"black":"white";
}

// ===== SIMPLE AI =====
function getAIMove(board){
  for(let i=0;i<64;i++){
    if(board[i] && board[i]===board[i].toLowerCase()){
      let to=i+8;
      if(to<64 && !board[to]) return {from:i,to};
    }
  }
}

// ===== STATIC =====
app.use(express.static(path.join(__dirname,'public')));

server.listen(PORT,()=>console.log("Server running "+PORT));
JS

# ================= FRONTEND =================
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
<input id="user" placeholder="user">
<input id="pass" placeholder="pass">
<button onclick="login()">Login</button>
<button onclick="visitor()">Visitor</button>
</div>

<div class="page" id="chess">
<div id="board"></div>
</div>

<div class="page" id="chat">
<div id="chatBox"></div>
<input id="msg">
<button onclick="sendChat()">Send</button>
</div>

<div class="page" id="profile">
<div id="profileData"></div>
</div>

</div>

<script src="/socket.io/socket.io.js"></script>
<script>
const socket = io();
let board=[],player="white",roomId="room1",selected=null,myName="";

function openPage(id){
document.querySelectorAll(".page").forEach(p=>p.classList.remove("active"));
document.getElementById(id).classList.add("active");
if(id==="profile") loadProfile();
}

function login(){
myName=user.value;
fetch('/login',{method:'POST',headers:{'Content-Type':'application/json'},
body:JSON.stringify({username:myName,password:pass.value})})
.then(r=>r.json()).then(d=>{
if(!d.success)return alert("fail");
socket.emit("joinRoom",{roomId,username:myName});
});
}

function visitor(){
myName="guest"+Math.random();
socket.emit("joinRoom",{roomId,username:myName});
}

function draw(){
let h="";
board.forEach((p,i)=>{
h+=`<button onclick="clickCell(${i})">${p||"."}</button>`;
if((i+1)%8===0)h+="<br>";
});
board.innerHTML=h;
document.getElementById("board").innerHTML=h;
}

function clickCell(i){
if(selected===null) selected=i;
else{
socket.emit("move",{gameType:"chess",move:{from:selected,to:i},player});
selected=null;
}
}

socket.on("update",({gameType,game})=>{
if(gameType==="chess"){board=game.board;player=game.turn;draw();}
});

socket.on("chat",d=>{
chatBox.innerHTML+=`<div>${d.user}:${d.msg}</div>`;
});

function sendChat(){
socket.emit("chat",{user:myName,msg:msg.value});
}

function loadProfile(){
fetch('/api/profile').then(r=>r.json()).then(d=>{
profileData.innerHTML=`User:${d.name}<br>Role:${d.role}`;
});
}
</script>

</body>
</html>
HTML

# ================= CSS =================
cat > public/css/styles.css << 'CSS'
body{
background:#12121a;
color:white;
font-family:sans-serif;
}

#nav{
display:flex;
gap:10px;
padding:10px;
background:rgba(255,255,255,0.05);
backdrop-filter:blur(10px);
}

.page{
display:none;
opacity:0;
transition:0.3s;
}

.page.active{
display:block;
opacity:1;
}

button{
margin:2px;
padding:6px;
background:#333;
color:white;
border:none;
}

#board button{
width:40px;
height:40px;
}
CSS

echo "✅ DONE"
echo "Run: node index.js"
