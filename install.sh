#!/usr/bin/env bash

set -e

# AI Factory Skills Installer
# Usage: ./install.sh <skill-name> [target-directory]

SKILL_NAME=$1
TARGET_DIR=${2:-.}

if [ -z "$SKILL_NAME" ]; then
  echo "Usage: $0 <skill-name> [target-directory]"
  echo "Available skills:"
  ls -1 "$(dirname "$0")/skills" | sed 's/\.md$//'
  exit 1
fi

SKILL_FILE="$(dirname "$0")/skills/${SKILL_NAME}.md"

if [ ! -f "$SKILL_FILE" ]; then
  echo "Error: Skill '${SKILL_NAME}' not found at ${SKILL_FILE}."
  exit 1
fi

echo "Installing '${SKILL_NAME}' skill to ${TARGET_DIR}..."

# Ensure target directory exists
mkdir -p "$TARGET_DIR"

# 1. Cursor (.cursorrules)
cat "$SKILL_FILE" > "${TARGET_DIR}/.cursorrules"
echo "✅ Installed for Cursor (.cursorrules)"

# 2. Windsurf (.windsurfrules)
cat "$SKILL_FILE" > "${TARGET_DIR}/.windsurfrules"
echo "✅ Installed for Windsurf (.windsurfrules)"

# 3. Claude Code (CLAUDE.md)
cat "$SKILL_FILE" > "${TARGET_DIR}/CLAUDE.md"
echo "✅ Installed for Claude Code (CLAUDE.md)"

# 4. GitHub Copilot (.github/copilot-instructions.md)
mkdir -p "${TARGET_DIR}/.github"
cat "$SKILL_FILE" > "${TARGET_DIR}/.github/copilot-instructions.md"
echo "✅ Installed for GitHub Copilot (.github/copilot-instructions.md)"

# 5. Generic / Antigravity (system_prompt.md)
mkdir -p "${TARGET_DIR}/.antigravity"
cat "$SKILL_FILE" > "${TARGET_DIR}/.antigravity/instructions.md"
echo "✅ Installed for Antigravity (.antigravity/instructions.md)"

echo "Installation complete!"
