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
