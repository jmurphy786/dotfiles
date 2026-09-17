#!/bin/bash
# Clipboard history using cliphist + wofi (scrollable, closes on Escape)

case "${1:-}" in
    delete)
        selected=$(cliphist list | wofi --dmenu --prompt "  Delete" --height 400 --width 600 --insensitive --style ~/.config/wofi/style.css)
        if [ -n "$selected" ]; then
            echo "$selected" | cliphist delete
            notify-send "Clipboard" "Item deleted"
        fi
        ;;
    *)
        selected=$(cliphist list | wofi --dmenu --prompt "  Clipboard" --height 400 --width 600 --insensitive --style ~/.config/wofi/style.css)
        if [ -n "$selected" ]; then
            echo "$selected" | cliphist decode | wl-copy
            notify-send "Clipboard" "Copied to clipboard"
        fi
        ;;
esac
