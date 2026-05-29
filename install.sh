#!/usr/bin/env bash

set -e

# AI Factory Skills Installer
# Installs persistent skills into AI tool configuration files.
#
# Usage: ./install.sh [target-directory]
#   -f    Force overwrite existing files without prompting

FORCE=false
while getopts "f" opt; do
  case $opt in
    f) FORCE=true ;;
    *) ;;
  esac
done
shift $((OPTIND - 1))

TARGET_DIR=${1:-.}
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="${SCRIPT_DIR}/skills"

if [ ! -d "$SKILLS_DIR" ] || [ -z "$(ls -A "$SKILLS_DIR"/*.md 2>/dev/null)" ]; then
  echo "Error: No skills found in ${SKILLS_DIR}/"
  exit 1
fi

echo "Installing skills to ${TARGET_DIR}..."

# Ensure target directory exists
mkdir -p "$TARGET_DIR"

# Concatenate all skills into a temporary file
TMP_FILE=$(mktemp)
first=true
for skill in "$SKILLS_DIR"/*.md; do
  if [ "$first" = true ]; then
    first=false
  else
    printf "\n\n---\n\n" >> "$TMP_FILE"
  fi
  cat "$skill" >> "$TMP_FILE"
done

# Helper: write to a target file, respecting the --force flag
write_target() {
  local dest="$1"
  local label="$2"

  if [ -f "$dest" ] && [ "$FORCE" != true ]; then
    echo "⚠️  Skipped ${label} — ${dest} already exists (use -f to overwrite)"
    return
  fi

  local dir
  dir=$(dirname "$dest")
  mkdir -p "$dir"
  cat "$TMP_FILE" > "$dest"
  echo "✅ Installed ${label} (${dest})"
}

write_target "${TARGET_DIR}/.cursorrules"                      "Cursor"
write_target "${TARGET_DIR}/.windsurfrules"                    "Windsurf"
write_target "${TARGET_DIR}/CLAUDE.md"                         "Claude Code"
write_target "${TARGET_DIR}/.github/copilot-instructions.md"   "GitHub Copilot"
write_target "${TARGET_DIR}/.antigravity/instructions.md"      "Antigravity"

rm -f "$TMP_FILE"
echo ""
echo "Installation complete!"
echo "Note: Runbooks (e.g. porter.md) are not installed — reference them on demand."
echo "See ${SCRIPT_DIR}/README.md for details."
