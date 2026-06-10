#!/usr/bin/env bash
set -euo pipefail

# kitty-prompt.sh - Helper for kitty prompt-based actions
# Place this script in ~/.config/kitty/ alongside kitty.conf
# Usage: kitty-prompt.sh <new-workspace|rename-workspace>

mode="${1:-}"

case "$mode" in
  new-workspace)
    name=$(kitty +kitten ask --type=line --message "Enter new workspace name" --prompt "> ")
    if [ -n "$name" ]; then
      kitty @ launch --type=tab
      kitty @ set-tab-title "$name"
    fi
    ;;
  rename-workspace)
    name=$(kitty +kitten ask --type=line --message "Enter new workspace name" --prompt "> ")
    if [ -n "$name" ]; then
      kitty @ set-tab-title "$name"
    fi
    ;;
  *)
    echo "Unknown mode: $mode" >&2
    echo "Usage: $0 <new-workspace|rename-workspace>" >&2
    exit 1
    ;;
esac
