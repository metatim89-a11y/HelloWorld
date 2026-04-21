#!/data/data/com.termux/files/usr/bin/bash

echo "🧭 Fixing navigation cleanly..."

FILE="public/index.html"

# ===== REMOVE any fetch-based nav =====
sed -i '/fetch(.*\.html/d' "$FILE"

# ===== REPLACE openPage FUNCTION =====
awk '
BEGIN{skip=0}
/function openPage\(/{
  skip=1
  print "function openPage(id){"
  print "  document.querySelectorAll(\".page\").forEach(p=>p.classList.remove(\"active\"));"
  print "  const el = document.getElementById(id);"
  print "  if(el){ el.classList.add(\"active\"); }"
  print "  else { console.error(\"Page not found:\", id); }"
  print "}"
  next
}
skip && /}/{
  skip=0
  next
}
skip{next}
{print}
' "$FILE" > tmp && mv tmp "$FILE"

echo "✅ openPage fixed"

# ===== ENSURE pages wrapper =====
grep -q 'id="pages"' "$FILE" || sed -i '/<body>/a <div id="pages"></div>' "$FILE"

# ===== ENSURE CORE PAGES =====
grep -q 'id="home"' "$FILE" || sed -i '/id="pages"/a \
<div class="page active" id="home"><div class="card">Home</div></div>' "$FILE"

grep -q 'id="games"' "$FILE" || sed -i '/id="pages"/a \
<div class="page" id="games"><div class="card">Games</div></div>' "$FILE"

grep -q 'id="chat"' "$FILE" || sed -i '/id="pages"/a \
<div class="page" id="chat"><div class="card">Chat</div></div>' "$FILE"

grep -q 'id="profile"' "$FILE" || sed -i '/id="pages"/a \
<div class="page" id="profile"><div class="card">Profile</div></div>' "$FILE"

echo "✅ pages ensured"

echo "🔥 DONE — restart server + hard refresh"
