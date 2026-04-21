#!/data/data/com.termux/files/usr/bin/bash

echo "🔧 Patching project..."

FILE="public/index.html"

# ===== FIX LOGIN FUNCTION =====
sed -i '/function login()/,/^}/c\
function login(){\
  myName = document.getElementById("user").value;\
  fetch("/login",{\
    method:"POST",\
    headers:{"Content-Type":"application/json"},\
    body:JSON.stringify({username:myName})\
  })\
  .then(res => res.json())\
  .then(data => {\
    if (!data.success) {\
      alert("Login failed");\
      return;\
    }\
    socket.emit("joinRoom",{roomId,username:myName});\
  })\
  .catch(err => {\
    console.error(err);\
    alert("Server error");\
  });\
}' "$FILE"

# ===== ADD VISITOR FUNCTION (if missing) =====
grep -q "function visitor()" "$FILE" || sed -i '/<\/script>/i\
function visitor(){\
  myName = "Visitor_" + Math.floor(Math.random()*10000);\
  socket.emit("joinRoom",{roomId,username:myName});\
}\
' "$FILE"

# ===== ADD VISITOR BUTTON (if missing) =====
grep -q "Play as Visitor" "$FILE" || sed -i '/Login<\/button>/a\
<button onclick="visitor()">Play as Visitor</button>' "$FILE"

# ===== FIX CSS PATH =====
sed -i 's|href="style.css"|href="/css/styles.css"|g' "$FILE"

echo "✅ Patch complete"
