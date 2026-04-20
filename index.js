const express = require('express');
const session = require('express-session');
const path = require('path');
const os = require('os');
const { exec } = require('child_process');

const app = express();
const PORT = 3000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use(session({
  secret: 'secret-key',
  resave: false,
  saveUninitialized: true
}));

function requireAuth(req, res, next) {
  if (req.session.user) return next();
  return res.redirect('/login');
}

const USERS = {
  RobV: "RobV",
  TimM: "TimM",
  admin: "1234"
};

// LOGIN
app.get('/login', (req, res) => {
  res.sendFile(path.join(__dirname, 'public/login.html'));
});

app.post('/login', (req, res) => {
  const { username, password } = req.body;

  if (USERS[username] && USERS[username] === password) {
    req.session.user = username;
    return res.redirect('/');
  }

  res.send('Login failed');
});

app.get('/logout', (req, res) => {
  req.session.destroy(() => res.redirect('/login'));
});

// 🔥 HEALTH (NOW RETURNS PAGE INSTEAD OF JUST JSON)
app.get('/health', requireAuth, (req, res) => {
  res.send(`
    <html>
    <body style="background:black;color:lime;font-family:monospace;padding:20px">
      <h2>Health Check</h2>
      <p>Status: OK</p>
      <p>PID: ${process.pid}</p>
      <p>User: ${req.session.user}</p>
      <p>Platform: ${os.platform()}</p>
      <a href="/" style="color:cyan">← Back</a>
    </body>
    </html>
  `);
});

// TERMINAL
app.post('/api/exec', requireAuth, (req, res) => {
  const { cmd } = req.body;

  exec(cmd, { timeout: 5000 }, (err, stdout, stderr) => {
    if (err) return res.json({ output: stderr || err.message });
    res.json({ output: stdout });
  });
});

// CHAT
let messages = [];

app.get('/api/chat', requireAuth, (req, res) => {
  res.json(messages);
});

app.post('/api/chat', requireAuth, (req, res) => {
  messages.push({
    user: req.session.user,
    text: req.body.text
  });
  if (messages.length > 50) messages.shift();
  res.json({ ok: true });
});

// MAIN
app.get('/', requireAuth, (req, res) => {
  res.sendFile(path.join(__dirname, 'public/index.html'));
});

app.listen(PORT, () => {
  console.log("[STARTED] http://localhost:3000");
});
