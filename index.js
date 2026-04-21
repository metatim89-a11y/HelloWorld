const express = require('express');
const session = require('express-session');
const path = require('path');
const http = require('http');
const { Server } = require('socket.io');
const { exec } = require('child_process');

const app = express();
const server = http.createServer(app);
const io = new Server(server);

const PORT = 3000;

app.use(express.json());

// ===== SESSION =====
app.use(session({
  secret: 'dev-secret-key',
  resave: false,
  saveUninitialized: false
}));

// ===== USERS =====
const users = {
  RobV: { role: 'admin' },
  TimM: { role: 'user' }
};

// ===== ROUTES =====
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.post('/login', (req, res) => {
  const { username } = req.body;

  if (!users[username]) {
    return res.status(403).json({ error: 'Invalid user' });
  }

  req.session.user = {
    name: username,
    role: users[username].role
  };

  res.json({ success: true, user: req.session.user });
});

app.get('/me', (req, res) => {
  if (!req.session.user) {
    return res.status(401).json({ error: 'Not logged in' });
  }
  res.json({ user: req.session.user });
});

app.post('/logout', (req, res) => {
  req.session.destroy(() => res.json({ success: true }));
});

// ===== SAFE TERMINAL =====
app.post('/terminal', (req, res) => {
  const { cmd } = req.body;

  const allowed = ['ls', 'pwd', 'whoami'];

  if (!allowed.includes(cmd.split(' ')[0])) {
    return res.json({ output: 'Command not allowed' });
  }

  exec(cmd, (err, stdout, stderr) => {
    res.json({ output: stdout || stderr });
  });
});

// ===== SOCKET CHAT =====
let usersOnline = {};

io.on('connection', (socket) => {

  socket.on('login', (username) => {
    usersOnline[username] = socket.id;
    io.emit('users', Object.keys(usersOnline));
  });

  socket.on('chat', (msg) => {
    io.emit('chat', msg);
  });

  socket.on('disconnect', () => {
    for (let u in usersOnline) {
      if (usersOnline[u] === socket.id) {
        delete usersOnline[u];
      }
    }
    io.emit('users', Object.keys(usersOnline));
  });
});

// ===== STATIC =====
app.use(express.static(path.join(__dirname, 'public')));

// ===== FALLBACK =====
app.use((req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// ===== START =====
server.listen(PORT, () => {
  console.log("Server running on port " + PORT);
});
