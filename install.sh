#!/usr/bin/env bash

set -e

# AI Factory Skills Installer
# Usage: ./install.sh [target-directory]

TARGET_DIR=${1:-.}
SKILLS_DIR="$(dirname "$0")/skills"

echo "Installing all skills to ${TARGET_DIR}..."

# Ensure target directory exists
mkdir -p "$TARGET_DIR"

# Concatenate all skills into a temporary file
TMP_FILE=$(mktemp)
for skill in "$SKILLS_DIR"/*.md; do
  cat "$skill" >> "$TMP_FILE"
  echo -e "\n\n---\n\n" >> "$TMP_FILE"
done

# 1. Cursor (.cursorrules)
cat "$TMP_FILE" > "${TARGET_DIR}/.cursorrules"
echo "✅ Installed for Cursor (.cursorrules)"

# 2. Windsurf (.windsurfrules)
cat "$TMP_FILE" > "${TARGET_DIR}/.windsurfrules"
echo "✅ Installed for Windsurf (.windsurfrules)"

# 3. Claude Code (CLAUDE.md)
cat "$TMP_FILE" > "${TARGET_DIR}/CLAUDE.md"
echo "✅ Installed for Claude Code (CLAUDE.md)"

# 4. GitHub Copilot (.github/copilot-instructions.md)
mkdir -p "${TARGET_DIR}/.github"
cat "$TMP_FILE" > "${TARGET_DIR}/.github/copilot-instructions.md"
echo "✅ Installed for GitHub Copilot (.github/copilot-instructions.md)"

# 5. Generic / Antigravity (instructions.md)
mkdir -p "${TARGET_DIR}/.antigravity"
cat "$TMP_FILE" > "${TARGET_DIR}/.antigravity/instructions.md"
echo "✅ Installed for Antigravity (.antigravity/instructions.md)"

rm -f "$TMP_FILE"
echo "Installation complete!"
