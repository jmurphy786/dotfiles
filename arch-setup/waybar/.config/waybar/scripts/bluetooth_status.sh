#!/bin/bash

# Check if bluetoothctl is available
if ! command -v bluetoothctl &>/dev/null; then
    echo ""
    exit 0
fi

# Check if a default controller exists
controller=$(bluetoothctl list 2>/dev/null | head -n1)
if [ -z "$controller" ]; then
    echo ""
    exit 0
fi

status=$(bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2}')
if [ "$status" == "yes" ]; then
    echo ""
else
    echo ""
fi
