#!/usr/bin/env bash
set -euo pipefail

# kitty-workspace.sh - Robust workspace (tab) management for kitty
# Usage: kitty-workspace.sh <new|rename|switch|close>

mode="${1:-}"

get_tabs() {
    kitty @ ls | jq -r '.[0].tabs[] | "\(.id)\t\(.title)"'
}

switch_tab() {
    local tabs="$(get_tabs)"
    if [ -z "$tabs" ]; then
        echo "No tabs found."
        exit 0
    fi

    local selected
    selected=$(echo "$tabs" | awk -F'\t' '{print $1 ": " $2}' | fzf --prompt="Switch workspace: " --height=40% --layout=reverse --border)

    if [ -n "$selected" ]; then
        local tab_id="$(echo "$selected" | cut -d: -f1)"
        kitty @ focus-tab --match "id:${tab_id}"
    fi
}

new_workspace() {
    printf "Enter new workspace name: "
    read -r name
    if [ -n "$name" ]; then
        kitty @ launch --type=tab
        kitty @ set-tab-title "$name"
    fi
}

rename_workspace() {
    printf "Enter new workspace name: "
    read -r name
    if [ -n "$name" ]; then
        kitty @ set-tab-title "$name"
    fi
}

case "$mode" in
    new|n)
        new_workspace
        ;;
    rename|r)
        rename_workspace
        ;;
    switch|s)
        switch_tab
        ;;
    close|c)
        kitty @ close-tab
        ;;
    *)
        echo "Usage: $0 <new|rename|switch|close>"
        exit 1
        ;;
esac
