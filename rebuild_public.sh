#!/data/data/com.termux/files/usr/bin/bash

echo "📁 Rebuilding public folder..."

mkdir -p public/css

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
 let password=document.getElementById("pass").value || "";

 fetch("/login",{
  method:"POST",
  headers:{"Content-Type":"application/json"},
  body:JSON.stringify({username:myName,password})
 })
 .then(r=>r.json())
 .then(d=>{
  if(!d.success) return alert("Login failed");
  socket.emit("joinRoom",{roomId,username:myName});
 })
 .catch(()=>alert("Server error"));
}

function visitor(){
 myName="Visitor_"+Math.floor(Math.random()*9999);
 socket.emit("joinRoom",{roomId,username:myName});
}

function draw(){
 let h="";
 board.forEach((p,i)=>{
  h+=\`<button onclick="clickCell(\${i})">\${p||"."}</button>\`;
  if((i+1)%8===0) h+="<br>";
 });
 document.getElementById("board").innerHTML=h;
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
 if(r.chess){
  board=r.chess.board;
  player=r.chess.turn;
  draw();
 }
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
 document.getElementById("chatBox").innerHTML += \`<div>\${d.user}: \${d.msg}</div>\`;
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
  background:rgba(255,255,255,0.05);
  backdrop-filter:blur(10px);
}

.page {
  display:none;
  opacity:0;
  transition:0.3s;
}

.page.active {
  display:block;
  opacity:1;
}

.card {
  margin:20px;
  padding:15px;
  border-radius:12px;
  background:rgba(255,255,255,0.08);
  backdrop-filter:blur(10px);
}

button {
  margin:2px;
  padding:8px;
  border:none;
  border-radius:6px;
  cursor:pointer;
  background:rgba(255,255,255,0.15);
  color:white;
}

button:hover {
  background:rgba(255,255,255,0.3);
}

#board button {
  width:40px;
  height:40px;
}
CSS

echo "✅ public/ rebuilt successfully"
