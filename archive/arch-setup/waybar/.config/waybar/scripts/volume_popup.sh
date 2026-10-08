#!/bin/bash
# Wrapper to launch the GTK volume slider popup (single instance)
if pgrep -f "volume_popup.py" > /dev/null; then
    pkill -f "volume_popup.py"
    exit 0
fi
exec python3 ~/.config/waybar/scripts/volume_popup.py
