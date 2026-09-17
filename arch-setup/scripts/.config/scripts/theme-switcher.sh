#!/bin/bash
# Theme Switcher Script - Sway edition
WALLPAPER_DIR="$HOME/assets"
CURRENT_WALLPAPER_FILE="$HOME/.cache/current_wallpaper"

# Collect wallpapers
mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | sort)

if [ ${#WALLPAPERS[@]} -eq 0 ]; then
  notify-send "Theme Switcher" "No wallpapers found in $WALLPAPER_DIR"
  exit 1
fi

# Helpers
get_current_index() {
  [[ -f "$CURRENT_WALLPAPER_FILE" ]] && cat "$CURRENT_WALLPAPER_FILE" || echo "0"
}

apply_theme() {
  local wallpaper_path="$1"
  local index="$2"
  local wallpaper_name
  wallpaper_name=$(basename "$wallpaper_path")

  echo "$index" >"$CURRENT_WALLPAPER_FILE"

  # Kill existing swaybg and restart on all outputs
  pkill -x swaybg
  sleep 0.1

  # Apply wallpaper to both monitors
  swaybg -o HDMI-A-1 -i "$wallpaper_path" -m fill &
  swaybg -o DP-2 -i "$wallpaper_path" -m fill &

  notify-send "Theme Switcher" "Applied: $wallpaper_name"
}

restore_theme() {
  local index=$(get_current_index)
  apply_theme "${WALLPAPERS[$index]}" "$index"
}

# Main
case "${1:-next}" in
"next")
  next_index=$((($(get_current_index) + 1) % ${#WALLPAPERS[@]}))
  apply_theme "${WALLPAPERS[$next_index]}" "$next_index"
  ;;
"random")
  random_index=$((RANDOM % ${#WALLPAPERS[@]}))
  apply_theme "${WALLPAPERS[$random_index]}" "$random_index"
  ;;
"restore")
  restore_theme
  ;;
"list")
  # Show filenames with icon in wofi
  selected=$(printf "%s\n" "${WALLPAPERS[@]##*/}" | sed 's/^/  /' | wofi --dmenu --prompt "Choose Wallpaper" --insensitive --style ~/.config/wofi/style.css)

  if [ -n "$selected" ]; then
    # Strip icon prefix before matching
    selected_clean=$(echo "$selected" | sed 's/^  //')
    for i in "${!WALLPAPERS[@]}"; do
      if [[ "${WALLPAPERS[$i]##*/}" == "$selected_clean" ]]; then
        apply_theme "${WALLPAPERS[$i]}" "$i"
        break
      fi
    done
  else
    notify-send "Theme Switcher" "No wallpaper selected."
  fi
  ;;
esac
