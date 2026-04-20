# File: ./filemaker001.sh
# Version: 0.001
# Purpose: Initialize project structure, remove invalid directories, and create required base files
# Notes: Idempotent-safe for initial setup

SCRIPT_NAME="filemaker001.sh"

# === Cleanup incorrect directory (comma mistake) ===
rm -rf .LOGS,.SCRIPT,.ALIASES,.FUNCTIONS,public 2>> ./.LOGS/${SCRIPT_NAME}.err

# === Ensure required directories exist ===
mkdir -p ./.LOGS ./.SCRIPT ./.ALIASES ./.FUNCTIONS ./public 2>> ./.LOGS/${SCRIPT_NAME}.err

# === Create CHANGES log (append-only) ===
cat << 'EOC' >> ./.LOGS/CHANGES.md
# File: ./.LOGS/CHANGES.md
# Version: 0.001
# Purpose: Append-only change tracking log

[04.19.2026:INIT] Project initialized via filemaker001.sh

# LLM SIGNATURE: (ChatGPT:GPT-5.3) 04.19.2026:04:48AM:Tim
EOC

# === Create PROJECT RC ===
cat << 'EOC' > ./.PROJECT.RC
# File: ./.PROJECT.RC
# Version: 0.001
# Purpose: Project environment activation

export PATH="./.SCRIPT:$PATH"

[ -f "./.ALIASES/aliases.sh" ] && source "./.ALIASES/aliases.sh"
[ -f "./.FUNCTIONS/functions.sh" ] && source "./.FUNCTIONS/functions.sh"

# LLM SIGNATURE: (ChatGPT:GPT-5.3) 04.19.2026:04:48AM:Tim
EOC

# === Aliases ===
cat << 'EOC' > ./.ALIASES/aliases.sh
# File: ./.ALIASES/aliases.sh
# Version: 0.001
# Purpose: Project aliases

alias ll='ls -la'
alias start='node ./index.js'

# LLM SIGNATURE: (ChatGPT:GPT-5.3) 04.19.2026:04:48AM:Tim
EOC

# === Functions ===
cat << 'EOC' > ./.FUNCTIONS/functions.sh
# File: ./.FUNCTIONS/functions.sh
# Version: 0.001
# Purpose: Helper functions

log_change() {
  echo "[$(date '+%m.%d.%Y:%H:%M:%S')] $1" >> ./.LOGS/CHANGES.md
}

# LLM SIGNATURE: (ChatGPT:GPT-5.3) 04.19.2026:04:48AM:Tim
EOC

# === audit.sh ===
cat << 'EOC' > ./.SCRIPT/audit.sh
# File: ./.SCRIPT/audit.sh
# Version: 0.001
# Purpose: Generate audit report

SCRIPT_NAME="audit.sh"

echo "=== PROJECT AUDIT ===" > ./.LOGS/AUDIT.md
ls -la >> ./.LOGS/AUDIT.md 2>> ./.LOGS/${SCRIPT_NAME}.err

echo "([Script]:$SCRIPT_NAME) $(date '+%m.%d.%Y:%H:%M:%S')" >> ./.LOGS/AUDIT.md
EOC

# === cleanup.sh ===
cat << 'EOC' > ./.SCRIPT/cleanup.sh
# File: ./.SCRIPT/cleanup.sh
# Version: 0.001
# Purpose: Cleanup logs or targets

SCRIPT_NAME="cleanup.sh"

TARGET=$1

if [ -z "$TARGET" ]; then
  rm -f ./.LOGS/*.err 2>> ./.LOGS/${SCRIPT_NAME}.err
else
  rm -f "$TARGET" 2>> ./.LOGS/${SCRIPT_NAME}.err
fi

echo "([Script]:$SCRIPT_NAME) $(date '+%m.%d.%Y:%H:%M:%S')" >> ./.LOGS/CHANGES.md
EOC

# === Captains Log ===
cat << 'EOC' >> ./.LOGS/CaptainsLog.md
# File: ./.LOGS/CaptainsLog.md
# Version: 0.001
# Purpose: Project reflection log

[04.19.2026:INIT]
Strengths:
- Structure initialized
- Protocol enforced
- Cleanup handled

Growth:
- No server yet
- No API
- No UI logic

LLM Insights:
- Start minimal
- Validate step-by-step
- Avoid overbuilding early

# LLM SIGNATURE: (ChatGPT:GPT-5.3) 04.19.2026:04:48AM:Tim
EOC

# === Final log entry ===
echo "[$(date '+%m.%d.%Y:%H:%M:%S')] filemaker001.sh executed" >> ./.LOGS/CHANGES.md

echo "([Script]:$SCRIPT_NAME) $(date '+%m.%d.%Y:%H:%M:%S')" >> ./.LOGS/CHANGES.md

