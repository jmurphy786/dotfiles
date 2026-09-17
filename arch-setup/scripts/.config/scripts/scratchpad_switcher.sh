#!/bin/bash
# Scratchpad switcher for Sway using wofi
# Usage: ~/.config/scripts/scratchpad_switcher.sh

# Get all scratchpad windows
windows=$(swaymsg -t get_tree | jq -r '
    .. | objects
    | select(.scratchpad_state == "fresh" and .name != null)
    | "\(.id)|\(.name)"
')

if [ -z "$windows" ]; then
    notify-send "Scratchpad" "No windows in scratchpad"
    exit 0
fi

# Build menu with a close option
menu="[Close window...]
$(echo "$windows" | cut -d'|' -f2-)"

selected=$(echo "$menu" | wofi --dmenu --prompt "Scratchpad" --height 400 --width 600 --insensitive --style ~/.config/wofi/style.css)

if [ -z "$selected" ]; then
    exit 0
fi

if [ "$selected" = "[Close window...]" ]; then
    # Pick which window to close
    to_close=$(echo "$windows" | cut -d'|' -f2- | wofi --dmenu --prompt "Close which?" --height 400 --width 600 --insensitive --style ~/.config/wofi/style.css)
    if [ -n "$to_close" ]; then
        id=$(echo "$windows" | grep "|${to_close}$" | head -n1 | cut -d'|' -f1)
        if [ -n "$id" ]; then
            swaymsg "[con_id=$id] kill"
        fi
    fi
else
    # Show the selected scratchpad window
    id=$(echo "$windows" | grep "|${selected}$" | head -n1 | cut -d'|' -f1)
    if [ -n "$id" ]; then
        swaymsg "[con_id=$id] scratchpad show"
    fi
fi
