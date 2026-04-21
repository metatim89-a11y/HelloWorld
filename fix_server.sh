#!/data/data/com.termux/files/usr/bin/bash

echo "🧹 Cleaning broken server code..."

# 1. REMOVE bad inline onlineUsers inside users object
sed -i '/const users = {/,/};/{
/onlineUsers/d
}' index.js

# 2. ENSURE single global onlineUsers (AFTER users block)
grep -q "let onlineUsers" index.js || sed -i '/const users = {/,/};/a \
\
let onlineUsers = {};\
' index.js

# 3. REMOVE duplicate disconnect handlers
awk '
!/socket.on\("disconnect"/ { print }
' index.js > tmp && mv tmp index.js

# 4. ADD clean disconnect handler ONCE
grep -q "CLEAN_DISCONNECT" index.js || sed -i '/io.on.*connection/a \
\
  // CLEAN_DISCONNECT\
  socket.on("disconnect", ()=>{\
    if(socket.username){\
      delete onlineUsers[socket.username];\
      io.emit("userList", { online:Object.keys(onlineUsers), all:Object.keys(users) });\
    }\
  });\
' index.js

# 5. FIX duplicate joinRoom inserts
awk '
!/onlineUsers\[username\] = true/ || !seen++ { print }
' index.js > tmp && mv tmp index.js

echo "✅ Server fixed"
