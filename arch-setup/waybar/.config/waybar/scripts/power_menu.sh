#!/bin/bash
# Power menu using wofi (themed)
options=("  Lock" "  Logout" "󰤄  Sleep" "  Restart" "  Shutdown")

chosen=$(printf '%s\n' "${options[@]}" | wofi --dmenu --prompt "Power Menu" --style ~/.config/wofi/style.css)

case "$chosen" in
    "  Lock")
        loginctl lock-session
        ;;
    "  Logout")
        swaymsg exit
        ;;
    "󰤄  Sleep")
        systemctl suspend
        ;;
    "  Restart")
        systemctl reboot
        ;;
    "  Shutdown")
        systemctl poweroff
        ;;
esac
