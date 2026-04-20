#!/data/data/com.termux/files/usr/bin/bash

echo "=== [FIX UI + HEALTH] ==="

# =========================
# index.js FIX
# =========================
cat << 'EON' > ./index.js
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
EON

# =========================
# UI WITH POPUPS
# =========================
cat << 'EON' > ./public/index.html
<!DOCTYPE html>
<html>
<body style="background:black;color:lime;font-family:monospace">

<!-- NAV -->
<div style="position:absolute;top:10px;right:20px">
  <a href="/" style="color:lime;margin-right:10px">Home</a>
  <a href="/health" style="color:lime;margin-right:10px">Health</a>
  <a href="/logout" style="color:red">Logout</a>
</div>

<h2>Dashboard</h2>

<button onclick="toggle('termBox')">Toggle Terminal</button>
<button onclick="toggle('chatBox')">Toggle Chat</button>

<!-- TERMINAL -->
<div id="termBox" style="border:1px solid #333;margin-top:10px;padding:10px">
  <h3>Terminal</h3>
  <div id="terminal" style="height:200px;overflow:auto"></div>
  <input id="cmd" style="width:100%;background:black;color:lime;border:none" placeholder="command..." />
</div>

<!-- CHAT -->
<div id="chatBox" style="border:1px solid #333;margin-top:10px;padding:10px">
  <h3>Chat</h3>
  <div id="chat" style="height:200px;overflow:auto"></div>
  <input id="msg" style="width:80%" />
  <button onclick="sendMsg()">Send</button>
</div>

<script>
function toggle(id) {
  const el = document.getElementById(id);
  el.style.display = (el.style.display === 'none') ? 'block' : 'none';
}

// TERMINAL
document.getElementById('cmd').addEventListener('keydown', async (e) => {
  if (e.key === 'Enter') {
    const cmd = e.target.value;

    const res = await fetch('/api/exec', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ cmd })
    });

    const data = await res.json();

    const term = document.getElementById('terminal');
    term.innerText += "\\n$ " + cmd + "\\n" + data.output;
    term.scrollTop = term.scrollHeight;

    e.target.value = "";
  }
});

// CHAT
async function loadChat() {
  const res = await fetch('/api/chat');
  const data = await res.json();

  document.getElementById('chat').innerText =
    data.map(m => "[" + m.user + "] " + m.text).join("\\n");
}

async function sendMsg() {
  const text = document.getElementById('msg').value;

  await fetch('/api/chat', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({ text })
  });

  document.getElementById('msg').value = "";
  loadChat();
}

setInterval(loadChat, 2000);
</script>

</body>
</html>
EON

echo "[DONE] Fixed health + added popup UI"
