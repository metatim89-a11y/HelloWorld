#!/data/data/com.termux/files/usr/bin/bash

LOG_DIR="./.LOGS"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# =========================
# CHANGES LOG
# =========================
cat << EOC >> "$LOG_DIR/changes.md"

## [$TIMESTAMP]

### 🔄 Auto Update
- Server start/rebuild triggered log update
- System state captured automatically

---

EOC

# =========================
# CAPTAIN'S LOG
# =========================
cat << EOC >> "$LOG_DIR/captains_log.md"

## 🧭 Captain's Log — $TIMESTAMP

### ⚙️ System Event
Auto-log triggered (server/rebuild)

### 🧠 LLM Reminder
- Keep infra stable before feature expansion
- Use logs instead of guessing system state
- Validate process, not just output

---

EOC

echo "[AUTO-LOG] Updated @ $TIMESTAMP"
