#!/usr/bin/env bash
# normal-gpt installer
# Usage: bash install.sh [--uninstall]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROMPT_FILE="$SCRIPT_DIR/prompt.md"
MARKER_BEGIN="# --- normal-gpt BEGIN ---"
MARKER_END="# --- normal-gpt END ---"

# Detect OpenClaw workspace
find_agents_md() {
  # Check common locations
  for dir in "." "$HOME" "${OPENCLAW_WORKSPACE:-}"; do
    [ -z "$dir" ] && continue
    [ -f "$dir/AGENTS.md" ] && echo "$dir/AGENTS.md" && return
  done
  echo ""
}

uninstall() {
  local agents_md
  agents_md=$(find_agents_md)
  if [ -z "$agents_md" ]; then
    echo "No AGENTS.md found. Nothing to uninstall."
    exit 0
  fi

  if grep -q "$MARKER_BEGIN" "$agents_md" 2>/dev/null; then
    # Remove the block between markers
    sed -i.bak "/$MARKER_BEGIN/,/$MARKER_END/d" "$agents_md"
    rm -f "${agents_md}.bak"
    echo "Uninstalled from $agents_md"
  else
    echo "normal-gpt not found in $agents_md"
  fi
}

install() {
  if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: prompt.md not found at $PROMPT_FILE"
    exit 1
  fi

  local agents_md
  agents_md=$(find_agents_md)

  # If no AGENTS.md found, create one in current directory
  if [ -z "$agents_md" ]; then
    agents_md="./AGENTS.md"
    echo "No AGENTS.md found. Creating $agents_md"
  fi

  # Check if already installed
  if grep -q "$MARKER_BEGIN" "$agents_md" 2>/dev/null; then
    echo "normal-gpt already installed in $agents_md. Run with --uninstall first to update."
    exit 0
  fi

  # Append prompt with markers
  {
    echo ""
    echo "$MARKER_BEGIN"
    cat "$PROMPT_FILE"
    echo "$MARKER_END"
  } >> "$agents_md"

  echo "Installed to $agents_md"
  echo "Start a new conversation to take effect."
}

if [ "${1:-}" = "--uninstall" ]; then
  uninstall
else
  install
fi
