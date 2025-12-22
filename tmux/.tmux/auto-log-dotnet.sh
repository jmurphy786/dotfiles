#!/bin/bash
# Define process types and their log files
declare -A log_files=(
  ["dotnet"]="$HOME/Documents/Github/aspire-dashboard/aspire-watch.log"
  ["node"]="$HOME/Documents/Github/logs/frontend.log"
  ["npm"]="$HOME/Documents/Github/logs/npm.log"
  ["expo"]="$HOME/Documents/Github/logs/mobile.log"
)

# Create log directory
mkdir -p "$HOME/Documents/Github/logs"

# Check all panes across all sessions
tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} #{pane_current_command}" | while read target cmd; do
# Check if this process should be logged
if [[ -n "${log_files[$cmd]}" ]]; then
  log_file="${log_files[$cmd]}"

        # Check if already piping
        is_piping=$(tmux display -p -t "$target" "#{pane_pipe}" 2>/dev/null)

        # Only enable if not already piping
        if [[ "$is_piping" == "0" ]]; then
          > "$log_file"
          # Enable logging
          if [[ "$cmd" == "dotnet" ]]; then
            tmux pipe-pane -t "$target" -o "ansifilter >> '$log_file'"
          else
            tmux pipe-pane -t "$target" -o "sed -u 's/\x1b\[[0-9;]*m//g' >> '$log_file'"
          fi
        fi
fi
done
