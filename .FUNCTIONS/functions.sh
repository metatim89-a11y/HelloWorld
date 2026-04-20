# File: ./.FUNCTIONS/functions.sh
# Version: 0.001
# Purpose: Helper functions

log_change() {
  echo "[$(date '+%m.%d.%Y:%H:%M:%S')] $1" >> ./.LOGS/CHANGES.md
}

# LLM SIGNATURE: (ChatGPT:GPT-5.3) 04.19.2026:04:48AM:Tim
