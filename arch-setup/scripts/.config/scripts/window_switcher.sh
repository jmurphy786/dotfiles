#!/bin/bash
# Window switcher for Sway using wofi
# Usage: ~/.config/scripts/window_switcher.sh

# Get all windows from sway tree
windows=$(swaymsg -t get_tree | jq -r '
    recurse(.nodes[]?, .floating_nodes[]?)
    | select(.type == "con" and .name != null)
    | "\(.id)|\(.name)"
')

if [ -z "$windows" ]; then
    exit 0
fi

# Show in wofi, strip the ID before display and add icon
selected=$(echo "$windows" | cut -d'|' -f2- | sed 's/^/  /' | wofi --dmenu --prompt "Windows" --height 400 --width 600 --insensitive --style ~/.config/wofi/style.css)

if [ -n "$selected" ]; then
    # Remove icon prefix for matching
    selected_clean=$(echo "$selected" | sed 's/^  //')
    # Find the ID for the selected name
    id=$(echo "$windows" | grep -F "|${selected_clean}$" | head -n1 | cut -d'|' -f1)
    if [ -n "$id" ]; then
        swaymsg "[con_id=$id] focus"
    fi
fi
