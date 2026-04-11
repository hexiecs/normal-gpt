#!/usr/bin/env bash
# talk-normal installer
# Usage: bash install.sh [--uninstall]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROMPT_FILE="$SCRIPT_DIR/prompt.md"
MARKER_BEGIN="# --- talk-normal BEGIN ---"
MARKER_END="# --- talk-normal END ---"

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
    echo "talk-normal not found in $agents_md"
  fi
}

install() {
  if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: prompt.md not found at $PROMPT_FILE"
    exit 1
  fi

  local agents_md
  local action="Installed"
  agents_md=$(find_agents_md)

  # If no AGENTS.md found, create one in current directory
  if [ -z "$agents_md" ]; then
    agents_md="./AGENTS.md"
    echo "No AGENTS.md found. Creating $agents_md"
  fi

  # If already installed, strip the old block first so re-running this script
  # performs an in-place update. This makes install.sh idempotent: the first
  # run installs, every subsequent run upgrades to the latest rules.
  if grep -q "$MARKER_BEGIN" "$agents_md" 2>/dev/null; then
    sed -i.bak "/$MARKER_BEGIN/,/$MARKER_END/d" "$agents_md"
    rm -f "${agents_md}.bak"
    action="Updated"
  fi

  # Append prompt with markers
  {
    echo ""
    echo "$MARKER_BEGIN"
    cat "$PROMPT_FILE"
    echo "$MARKER_END"
  } >> "$agents_md"

  echo "$action talk-normal in $agents_md"
  echo "Start a new conversation to take effect."
}

if [ "${1:-}" = "--uninstall" ]; then
  uninstall
else
  install
fi
