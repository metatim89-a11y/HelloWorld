# File: ./.SCRIPT/audit.sh
# Version: 0.001
# Purpose: Generate audit report

SCRIPT_NAME="audit.sh"

echo "=== PROJECT AUDIT ===" > ./.LOGS/AUDIT.md
ls -la >> ./.LOGS/AUDIT.md 2>> ./.LOGS/${SCRIPT_NAME}.err

echo "([Script]:$SCRIPT_NAME) $(date '+%m.%d.%Y:%H:%M:%S')" >> ./.LOGS/AUDIT.md
