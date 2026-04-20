#!/data/data/com.termux/files/usr/bin/bash

echo "=== [ADDING GLOBAL NAV] ==="

# =========================
# LOGIN PAGE
# =========================
cat << 'EON' > ./public/login.html
<!DOCTYPE html>
<html>
<body style="background:#111;color:white;padding:20px;font-family:monospace">

<!-- 🔗 NAV -->
<div style="position:absolute;top:10px;right:20px">
  <a href="/" style="color:lime;margin-right:10px">Home</a>
  <a href="/health" style="color:lime;margin-right:10px">Health</a>
  <a href="/login" style="color:lime;margin-right:10px">Login</a>
  <a href="/logout" style="color:red">Logout</a>
</div>

<h2>Login</h2>

<form method="POST" action="/login">
  <input name="username" placeholder="Username" /><br><br>
  <input name="password" type="password" placeholder="Password" /><br><br>
  <button type="submit">Login</button>
</form>

</body>
</html>
EON

# =========================
# MAIN UI
# =========================
cat << 'EON' > ./public/index.html
<!DOCTYPE html>
<html>
<body style="background:black;color:lime;font-family:monospace;padding:10px">

<!-- 🔗 NAV -->
<div style="position:absolute;top:10px;right:20px">
  <a href="/" style="color:lime;margin-right:10px">Home</a>
  <a href="/health" style="color:lime;margin-right:10px">Health</a>
  <a href="/login" style="color:lime;margin-right:10px">Login</a>
  <a href="/logout" style="color:red">Logout</a>
</div>

<h2>Web Terminal</h2>

<div id="terminal" style="height:300px;overflow:auto;border:1px solid #333;padding:10px"></div>

<div>
  <span>$ </span>
  <input id="cmd" style="width:90%;background:black;color:lime;border:none;outline:none" />
</div>

<hr>

<h3>Chat</h3>
<div id="chat" style="height:200px;overflow:auto;border:1px solid #333;padding:10px"></div>

<input id="msg" style="width:80%" placeholder="message..." />
<button onclick="sendMsg()">Send</button>

<script>
// TERMINAL
const term = document.getElementById('terminal');
const input = document.getElementById('cmd');

input.addEventListener('keydown', async (e) => {
  if (e.key === 'Enter') {
    const cmd = input.value;

    term.innerText += "\\n$ " + cmd;

    const res = await fetch('/api/exec', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ cmd })
    });

    const data = await res.json();

    term.innerText += "\\n" + data.output;
    term.scrollTop = term.scrollHeight;

    input.value = "";
  }
});

// CHAT
async function loadChat() {
  const res = await fetch('/api/chat');
  const data = await res.json();

  const box = document.getElementById('chat');
  box.innerText = data.map(m => "[" + m.user + "] " + m.text).join("\\n");
  box.scrollTop = box.scrollHeight;
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
loadChat();
</script>

</body>
</html>
EON

echo "[DONE] Navigation added to all pages"
