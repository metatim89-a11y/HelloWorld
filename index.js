const express = require('express');
const session = require('express-session');
const path = require('path');
const http = require('http');
const { Server } = require('socket.io');
const fs = require('fs');
const { exec, spawn, execSync } = require('child_process');

// CLEANUP: Kill any existing processes on ports 3000 and 11434
try {
  console.log("Cleaning up existing processes...");
  // Kill llama-server
  try { execSync('pkill -f llama-server'); } catch(e) {}
  // Kill anything on port 3000 (Node server)
  try { execSync('lsof -t -i:3000 | xargs kill -9'); } catch(e) {}
  console.log("Cleanup complete.");
} catch (err) {
  console.log("Cleanup note: No existing processes to clear.");
}

const app = express();
const server = http.createServer(app);
const io = new Server(server);

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(session({
  secret:'dev-secret-key',
  resave:false,
  saveUninitialized:false
}));

// USERS
let users = {
  RobV:{password:"RobV", profile: {name:"Robbie V", email:"rob@example.com", phone:"123456", address:"123 Dev Lane"}, stats: {wins:0, losses:0, draws:0, games:0}, history: []},
  TimM:{password:"TimM", profile: {name:"Tim M", email:"tim@example.com", phone:"654321", address:"456 Code Rd"}, stats: {wins:0, losses:0, draws:0, games:0}, history: []}
};
const USERS_FILE = './users.json';
if(fs.existsSync(USERS_FILE)) {
  users = JSON.parse(fs.readFileSync(USERS_FILE));
}
function saveUsers() {
  fs.writeFileSync(USERS_FILE, JSON.stringify(users, null, 2));
}

// Start llama-server for Gemma AI
const aiServer = spawn('/data/data/com.termux/files/home/llama.cpp/build/bin/llama-server', [
  '-m', '/data/data/com.termux/files/home/llama.cpp/build/gemma-4-2b.gguf',
  '--port', '11434',
  '--ctx-size', '2048',
  '--threads', '4',
  '--n-predict', '128'
], { detached: true });

aiServer.unref();

aiServer.stdout.on('data', (data) => console.log(`AI: ${data}`));
aiServer.stderr.on('data', (data) => console.error(`AI Error: ${data}`));

// AUTH_MIDDLEWARE
const requireAuth = (req, res, next) => {
  if (req.session && req.session.user) next();
  else res.redirect('/login.html');
};

// API_ROUTES
app.post('/api/signup', (req, res) => {
  const { username, password, name, email, phone, address } = req.body;
  if (!username || !password) return res.status(400).json({ success: false, error: "Username and password required" });
  if (users[username]) return res.status(400).json({ success: false, error: "User already exists" });

  users[username] = {
    password,
    profile: { name, email, phone, address },
    stats: { wins: 0, losses: 0, draws: 0, games: 0 },
    history: [],
    robvCoins: 0,
    timmCoins: 0,
    lastRobVClaim: 0,
    lastTimMClaim: 0
  };
  saveUsers();
  res.json({ success: true });
});

app.post('/api/claim-coin', requireAuth, (req, res) => {
  const { coinType } = req.body;
  const username = req.session.user.name;
  const user = users[username];

  if (!user) return res.status(404).json({ success: false, error: "User not found" });
  if (req.session.user.isGuest) return res.status(403).json({ success: false, error: "Guests cannot claim coins" });

  const now = Date.now();
  const dayMs = 24 * 60 * 60 * 1000;
  const claimField = coinType === 'RobV' ? 'lastRobVClaim' : 'lastTimMClaim';
  const coinField = coinType === 'RobV' ? 'robvCoins' : 'timmCoins';

  if (now - (user[claimField] || 0) < dayMs) {
    const remaining = dayMs - (now - user[claimField]);
    const hours = Math.ceil(remaining / (60 * 60 * 1000));
    return res.json({ success: false, error: `Wait ${hours} more hours` });
  }

  user[coinField] = (user[coinField] || 0) + 1000;
  user[claimField] = now;
  saveUsers();

  res.json({ success: true, balance: user[coinField] });
});

app.get('/api/profile', (req, res) => {
  if (!req.session.user) return res.status(401).json({error: "Not logged in"});
  const username = req.session.user.name;
  if (!users[username]) {
    if (req.session.user.isGuest) {
      return res.json({username, stats: {wins:0, losses:0, draws:0, games:0}, profile: {}, history: [], isGuest: true});
    }
    return res.status(404).json({error: "User not found"});
  }
  res.json({
    username, 
    profile: users[username].profile, 
    stats: users[username].stats,
    history: users[username].history,
    robvCoins: users[username].robvCoins || 0,
    timmCoins: users[username].timmCoins || 0,
    lastRobVClaim: users[username].lastRobVClaim || 0,
    lastTimMClaim: users[username].lastTimMClaim || 0
  });
});
app.get('/api/files', requireAuth, (req, res) => {
  const dir = req.query.path || '.';
  const fullPath = path.resolve(__dirname, dir);
  if (!fullPath.startsWith(__dirname)) return res.status(403).send("Access Denied");

  fs.readdir(fullPath, { withFileTypes: true }, (err, files) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(files.map(f => ({
      name: f.name,
      isDir: f.isDirectory(),
      path: path.join(dir, f.name)
    })));
  });
});

app.get('/api/read', requireAuth, (req, res) => {
  const filePath = req.query.path;
  const fullPath = path.resolve(__dirname, filePath);
  if (!fullPath.startsWith(__dirname)) return res.status(403).send("Access Denied");

  fs.readFile(fullPath, 'utf8', (err, data) => {
    if (err) return res.status(500).json({ error: err.message });
    res.send(data);
  });
});

app.post('/api/save', requireAuth, (req, res) => {
  const { path: filePath, content } = req.body;
  const fullPath = path.resolve(__dirname, filePath);
  if (!fullPath.startsWith(__dirname)) return res.status(403).send("Access Denied");

  fs.writeFile(fullPath, content, 'utf8', (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ success: true });
  });
});

app.post('/api/run', requireAuth, (req, res) => {
  const { path: filePath } = req.body;
  const fullPath = path.resolve(__dirname, filePath);
  if (!fullPath.startsWith(__dirname)) return res.status(403).send("Access Denied");

  let cmd = `node "${fullPath}"`;
  if (filePath.endsWith('.sh')) cmd = `bash "${fullPath}"`;
  else if (filePath.endsWith('.py')) cmd = `python3 "${fullPath}"`;

  exec(cmd, (err, stdout, stderr) => {
    res.json({ stdout, stderr, error: err ? err.message : null });
  });
});

// ... (existing users/stats/games logic) ...

// ROOMS
let rooms = {};
let games = {};
let onlineUsers = {};

// LOAD_GAMES
fs.readdirSync('./games').forEach(file=>{
  if(file.endsWith('.js')){
    const game = require('./games/'+file);
    games[game.name] = game;
    console.log("Loaded game:", game.name);
  }
});
// END_LOAD_GAMES

// LOGIN_ROUTE
app.get('/login', (req, res) => res.sendFile(path.join(__dirname, 'public/login.html')));

app.post('/login',(req,res)=>{
  const {username,password,isGuest}=req.body;
  
  if (isGuest) {
    // Allow guest login with any password
    req.session.user={name:username, isGuest:true};
    return res.json({success:true});
  }

  if(!users[username] || users[username].password!==password){
    if (req.headers['content-type'] === 'application/json') {
      return res.json({success:false});
    }
    return res.send('Login failed');
  }
  req.session.user={name:username};
  if (req.headers['content-type'] === 'application/json') {
    return res.json({success:true});
  }
  res.redirect('/');
});
// END_LOGIN_ROUTE

app.get('/health', (req, res) => res.json({status:'ok'}));
app.get('/logout', (req, res) => {
  req.session.destroy();
  res.redirect('/login');
});

// SOCKET_CORE
io.on('connection',socket=>{

// JOIN_ROOM
socket.on("join",({room,username})=>{
  socket.join(room);
  socket.room = room;
  socket.username = username;
  onlineUsers[username] = socket.id;

  io.emit("userList", { online:Object.keys(onlineUsers), all:Object.keys(users) });

  if(!rooms[room]){
    rooms[room] = {};

    for(let g in games){
      try{
        rooms[room][g] = games[g].init();
      }catch(e){
        console.log("Game init failed:", g);
      }
    }
  }

  socket.emit("state", rooms[room]);
});
// END_JOIN_ROOM

  // DISCONNECT
  socket.on("disconnect", ()=>{
    if(socket.username){
      delete onlineUsers[socket.username];
      io.emit("userList", { online:Object.keys(onlineUsers), all:Object.keys(users) });
    }
  });
  // END_DISCONNECT

  // GAME_HANDLER
  socket.on("game", async (data)=>{
    const {game, action, type} = data;
    if(!games[game]) return;
    if(!socket.room || !rooms[socket.room]) return;

    const g = rooms[socket.room][game];
    
    if (type === "undo") {
      if (games[game].undo) games[game].undo(g);
      g.recorded = false;
    } else if (type === "reset") {
      if (games[game].reset) games[game].reset(g);
      g.recorded = false;
    } else if (type === "toggleAI") {
      if (g.llmEnabled) {
        g.llmEnabled = false;
        g.aiEnabled = true; // Switching from LLM to CPU, force CPU on
        if (games[game].reset) games[game].reset(g);
      } else {
        if (games[game].toggleAI) games[game].toggleAI(g);
      }
      g.recorded = false;
    } else if (type === "toggleLLM") {
      g.llmEnabled = !g.llmEnabled;
      if (g.llmEnabled) {
        g.aiEnabled = true;
      } else {
        g.aiEnabled = false;
      }
      if (games[game].reset) games[game].reset(g);
      g.recorded = false;
    } else {
      games[game].move(g, action, socket.username);
    }

    // Record Stats and Learn if game just ended
    if (g.winner && !g.recorded) {
      g.recorded = true;
      const players = g.players; 
      const sideToUser = {};
      for (let u in players) sideToUser[players[u]] = u;

      const timestamp = new Date().toLocaleString();
      const userNames = Object.keys(players);

      if (!g.aiEnabled) {
        if (g.winner === "draw") {
          for (let u in players) {
            if (users[u]) {
              users[u].stats.draws++;
              users[u].stats.games++;
              users[u].history.unshift({
                game, result: "Draw", opponent: userNames.filter(name => name !== u).join(", ") || "Self", time: timestamp
              });
            }
          }
        } else {
          const winnerUser = sideToUser[g.winner];
          if (winnerUser && users[winnerUser]) {
            users[winnerUser].stats.wins++;
            users[winnerUser].stats.games++;
            users[winnerUser].history.unshift({
              game, result: "Win", opponent: userNames.filter(name => name !== winnerUser).join(", ") || "Self", time: timestamp
            });
          }
          for (let side in sideToUser) {
            const u = sideToUser[side];
            if (side !== g.winner && users[u]) {
              users[u].stats.losses++;
              users[u].stats.games++;
              users[u].history.unshift({
                game, result: "Loss", opponent: winnerUser || "Computer", time: timestamp
              });
            }
          }
        }
        saveUsers();
      } else if (g.llmEnabled) {
        // Learn from the game
        const logData = { game, winner: g.winner, history: g.history || [], time: timestamp };
        fs.appendFile('./llm_training_data.jsonl', JSON.stringify(logData) + '\n', (err) => {
          if (err) console.error("Error saving training data:", err);
        });
      }
    }

    io.to(socket.room).emit("game",{
      game,
      state:g
    });

    // Handle AI Move
    if (g.aiEnabled && !g.winner) {
      setTimeout(async () => {
        if (!g.aiEnabled || g.winner) return;
        
        if (g.llmEnabled) {
          await handleLLMMove(game, g, socket.room);
        } else if (games[game].computerMove) {
          games[game].computerMove(g);
          io.to(socket.room).emit("game",{ game, state:g });
        }
      }, 500);
    }
  });

  async function handleLLMMove(gameName, g, room) {
    let prompt = "";
    if (gameName === "tictactoe") {
      prompt = `You are a professional tictactoe player. 
Current board: ${JSON.stringify(g.board)}
Your symbol: ${g.turn}
Legal indices: ${g.board.map((v, i) => v === "" ? i : null).filter(v => v !== null).join(", ")}
Task: Return ONLY the index number (0-8) of your best move. No explanation.`;
    } else if (gameName === "connect4") {
      let validCols = [];
      for (let c = 0; c < 7; c++) { if (!g.board[c]) validCols.push(c); }
      prompt = `You are a professional connect4 player. 
Current board (42 cells): ${JSON.stringify(g.board)}
Your symbol: ${g.turn}
Legal columns: ${validCols.join(", ")}
Task: Return ONLY the column number (0-6) of your best move. No explanation.`;
    } else if (gameName === "chess") {
      const { Chess } = require('chess.js');
      const game = new Chess(g.fen);
      const moves = game.moves();
      prompt = `You are a professional chess player. 
Current FEN: ${g.fen}
Legal moves: ${moves.join(", ")}
Task: Return ONLY the SAN string of your best move (e.g., "e4" or "Nf3"). No explanation.`;
    }

    try {
      const response = await fetch("http://localhost:11434/completion", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ prompt, n_predict: 10, stream: false })
      });

      if (response.ok) {
        const data = await response.json();
        const reply = data.content.trim();
        
        if (gameName === "chess") {
          const { Chess } = require('chess.js');
          const game = new Chess(g.fen);
          const moves = game.moves();
          const san = moves.find(m => reply.includes(m)) || moves[Math.floor(Math.random() * moves.length)];
          const oldFen = g.fen;
          game.move(san);
          g.history.push(oldFen);
          g.fen = game.fen();
          g.board = games[gameName].getFlatBoard(game);
          g.turn = game.turn() === 'w' ? 'white' : 'black';
          if (game.isGameOver()) {
            if (game.isCheckmate()) g.winner = g.turn === 'white' ? 'black' : 'white';
            else g.winner = "draw";
          }
          io.to(room).emit("game", { game: gameName, state: g });
          io.to(room).emit("chat", { user: "🤖 Gemma AI", msg: `I played ${san}` });
        } else {
          const moveIndex = parseInt(reply.match(/\d+/));
          if (!isNaN(moveIndex)) {
            games[gameName].move(g, moveIndex, "GemmaAI");
            io.to(room).emit("game", { game: gameName, state: g });
            io.to(room).emit("chat", { user: "🤖 Gemma AI", msg: `I play at ${gameName==="connect4"?"column ":"index "}${moveIndex}` });
          }
        }
      }
    } catch (e) {
      console.error("LLM Move Error:", e);
    }
  }

  // GAME_CHAT_HANDLER
  socket.on("gameChat", (data) => {
    const { game, msg } = data;
    if (socket.room && game) {
      io.to(socket.room).emit("gameChat", {
        game: game,
        user: socket.username || "Guest",
        msg: msg
      });
    }
  });

  // CHAT_HANDLER
  socket.on("chat", async (msg) => {
    const username = socket.username || "Guest";
    const room = socket.room;
    const target = room ? io.to(room) : io;

    target.emit("chat", {
      user: username,
      msg: msg.msg
    });

    // Gemma AI Integration (via llama-server)
    if (msg.msg.toLowerCase().startsWith("@ai ")) {
      const prompt = msg.msg.slice(4);
      try {
        const response = await fetch("http://localhost:11434/completion", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            prompt: prompt,
            n_predict: 128,
            stream: false
          })
        });

        if (response.ok) {
          const data = await response.json();
          target.emit("chat", {
            user: "🤖 Gemma AI",
            msg: data.content
          });
        } else {
          target.emit("chat", {
            user: "🤖 Gemma AI",
            msg: "Error: AI server is busy or not responding."
          });
        }
      } catch (e) {
        target.emit("chat", {
          user: "🤖 Gemma AI",
          msg: "System: Could not connect to local AI instance."
        });
      }
    }
  });
  // END_CHAT_HANDLER

  // TERMINAL_HANDLER
  socket.on("terminal", (cmd) => {
    // Basic security: don't allow potentially destructive commands if not careful
    // But for this dev tool we'll allow it with exec
    exec(cmd, { cwd: __dirname }, (err, stdout, stderr) => {
      socket.emit("terminal", {
        stdout,
        stderr,
        error: err ? err.message : null
      });
    });
  });
  // END_TERMINAL_HANDLER

});
// END_SOCKET_CORE

app.use(express.static(path.join(__dirname,'public')));
server.listen(3000,()=>console.log("Server running 3000"));
