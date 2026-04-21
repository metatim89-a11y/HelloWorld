#!/data/data/com.termux/files/usr/bin/bash

echo "🔥 Rebuilding clean index.js..."

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

// ===== ONLINE USERS =====
let onlineUsers = {};

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

// ===== LOGIN =====
app.post('/login', (req,res)=>{
  const { username, password } = req.body;

  if (!users[username] || users[username].password !== password) {
    return res.json({ success:false });
  }

  req.session.user = { name: username };
  res.json({ success:true });
});

// ===== PROFILE =====
app.get('/api/profile',(req,res)=>{
  if(!req.session.user) return res.status(401).json({});
  res.json(req.session.user);
});

// ===== SOCKET =====
io.on('connection', (socket)=>{

  socket.on("joinRoom", ({roomId, username})=>{
    socket.join(roomId);
    socket.roomId = roomId;
    socket.username = username;

    // track online users
    onlineUsers[username] = true;
    io.emit("userList", {
      online: Object.keys(onlineUsers),
      all: Object.keys(users)
    });

    if (!rooms[roomId]) {
      rooms[roomId] = { chess: initChessGame() };
    }

    io.to(roomId).emit("roomData", rooms[roomId]);

    socket.emit("update", {
      gameType:"chess",
      game: rooms[roomId].chess
    });
  });

  socket.on("disconnect", ()=>{
    if(socket.username){
      delete onlineUsers[socket.username];
      io.emit("userList", {
        online: Object.keys(onlineUsers),
        all: Object.keys(users)
      });
    }
  });

  socket.on("chat", msg=>{
    io.emit("chat", msg);
  });

  socket.on("move", ({gameType, move})=>{
    let game = rooms[socket.roomId]?.[gameType];
    if (!game) return;

    game.board[move.to] = game.board[move.from];
    game.board[move.from] = "";
    game.turn = game.turn==="white"?"black":"white";

    io.to(socket.roomId).emit("update",{gameType,game});
  });

});

// ===== STATIC =====
app.use(express.static(path.join(__dirname,'public')));

// ===== START =====
server.listen(PORT,()=>console.log("Server running "+PORT));
JS

echo "✅ index.js FIXED"
