#!/bin/bash
# One-click setup: install statusline.sh and configure settings.json
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_SCRIPT="$HOME/.claude/statusline.sh"
SETTINGS="$HOME/.claude/settings.json"

# Check jq
if ! command -v jq &>/dev/null; then
  echo "Installing jq..."
  if command -v apt-get &>/dev/null; then
    sudo apt-get install -y jq
  elif command -v brew &>/dev/null; then
    brew install jq
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y jq
  else
    echo "ERROR: Please install jq manually."
    exit 1
  fi
fi

# Copy script
mkdir -p "$HOME/.claude"
cp "$SCRIPT_DIR/statusline.sh" "$TARGET_SCRIPT"
chmod +x "$TARGET_SCRIPT"
echo "Installed: $TARGET_SCRIPT"

# Merge statusLine into settings.json
if [ -f "$SETTINGS" ]; then
  # Add or update statusLine field
  tmp=$(mktemp)
  jq '.statusLine = {"type": "command", "command": "bash '"$TARGET_SCRIPT"'"}' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
else
  cat > "$SETTINGS" <<EOF
{
  "statusLine": {
    "type": "command",
    "command": "bash $TARGET_SCRIPT"
  }
}
EOF
fi

echo "Configured: $SETTINGS"
echo ""
echo "Done! Restart Claude Code to see the status line."
echo "Example: [Opus] Ctx: 37% (74k/200k)"
