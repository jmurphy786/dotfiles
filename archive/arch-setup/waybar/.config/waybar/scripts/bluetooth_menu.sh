#!/bin/bash
# Bluetooth menu with full device management via submenu

WOFI_OPTS="--dmenu --insensitive --style ${HOME}/.config/wofi/style.css"

main_menu() {
    local options=()

    powered=$(bluetoothctl show | awk '/Powered:/{print $2}')
    if [ "$powered" = "yes" ]; then
        options+=("󰂯  Power: ON (click to turn off)")
    else
        options+=("󰂲  Power: OFF (click to turn on)")
    fi

    options+=("  Scan for devices")
    options+=("󰥸  Open Blueman Manager")

    # Add known devices
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        mac=$(echo "$line" | awk '{print $2}')
        name=$(echo "$line" | cut -d' ' -f3-)

        info=$(bluetoothctl info "$mac" 2>/dev/null)
        connected=$(echo "$info" | awk '/Connected:/{print $2}')
        paired=$(echo "$info" | awk '/Paired:/{print $2}')
        trusted=$(echo "$info" | awk '/Trusted:/{print $2}')
        blocked=$(echo "$info" | awk '/Blocked:/{print $2}')

        tags=""
        [ "$paired" = "yes" ] && tags+="Paired,"
        [ "$connected" = "yes" ] && tags+="Connected,"
        [ "$trusted" = "yes" ] && tags+="Trusted,"
        [ "$blocked" = "yes" ] && tags+="Blocked,"
        [ -n "$tags" ] && tags=" (${tags%,})"

        options+=("󰟀  ${name}${tags}  [$mac]")
    done < <(bluetoothctl devices)

    selected=$(printf '%s\n' "${options[@]}" | wofi $WOFI_OPTS --prompt "Bluetooth" --height 450 --width 600)

    if [ -z "$selected" ]; then
        exit 0
    fi

    case "$selected" in
        "󰂯  Power: ON (click to turn off)")
            bluetoothctl power off
            notify-send "Bluetooth" "Bluetooth powered off"
            ;;
        "󰂲  Power: OFF (click to turn on)")
            bluetoothctl power on
            notify-send "Bluetooth" "Bluetooth powered on"
            ;;
        "  Scan for devices")
            bluetoothctl scan on &
            notify-send "Bluetooth" "Scanning for devices..."
            ;;
        "󰥸  Open Blueman Manager")
            blueman-manager &
            ;;
        *)
            # Extract MAC from brackets at the end
            mac=$(echo "$selected" | grep -oE '\[[0-9A-Fa-f:]+\]' | tr -d '[]')
            if [ -n "$mac" ]; then
                dev_name=$(echo "$selected" | sed 's/^[^ ]*  //; s/  \[.*//')
                device_menu "$mac" "$dev_name"
            fi
            ;;
    esac
}

device_menu() {
    local mac=$1
    local name=$2

    local info=$(bluetoothctl info "$mac" 2>/dev/null)
    local connected=$(echo "$info" | awk '/Connected:/{print $2}')
    local paired=$(echo "$info" | awk '/Paired:/{print $2}')
    local trusted=$(echo "$info" | awk '/Trusted:/{print $2}')
    local blocked=$(echo "$info" | awk '/Blocked:/{print $2}')

    local options=()
    options+=("󰌍  Back to main menu")

    if [ "$connected" = "yes" ]; then
        options+=("󰤯  Disconnect")
    else
        options+=("󰤥  Connect")
    fi

    if [ "$paired" = "yes" ]; then
        options+=("󰤨  Pair (already paired)")
    else
        options+=("󰤢  Pair")
    fi

    if [ "$trusted" = "yes" ]; then
        options+=("󰔡  Untrust")
    else
        options+=("󰔠  Trust")
    fi

    if [ "$blocked" = "yes" ]; then
        options+=("󰜙  Unblock")
    else
        options+=("󰜫  Block")
    fi

    options+=("󰩺  Remove device")

    selected=$(printf '%s\n' "${options[@]}" | wofi $WOFI_OPTS --prompt "$name" --height 350 --width 400)

    if [ -z "$selected" ]; then
        main_menu
        return
    fi

    case "$selected" in
        "󰌍  Back to main menu")
            main_menu
            return
            ;;
        "󰤥  Connect")
            bluetoothctl connect "$mac"
            notify-send "Bluetooth" "Connecting to $name..."
            ;;
        "󰤯  Disconnect")
            bluetoothctl disconnect "$mac"
            notify-send "Bluetooth" "Disconnected from $name"
            ;;
        "󰤢  Pair"|"󰤨  Pair (already paired)")
            bluetoothctl pair "$mac"
            notify-send "Bluetooth" "Pairing with $name..."
            ;;
        "󰔠  Trust")
            bluetoothctl trust "$mac"
            notify-send "Bluetooth" "$name trusted"
            ;;
        "󰔡  Untrust")
            bluetoothctl untrust "$mac"
            notify-send "Bluetooth" "$name untrusted"
            ;;
        "󰜫  Block")
            bluetoothctl block "$mac"
            notify-send "Bluetooth" "$name blocked"
            ;;
        "󰜙  Unblock")
            bluetoothctl unblock "$mac"
            notify-send "Bluetooth" "$name unblocked"
            ;;
        "󰩺  Remove device")
            bluetoothctl remove "$mac"
            notify-send "Bluetooth" "$name removed"
            ;;
    esac
}

main_menu
