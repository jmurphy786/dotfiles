# .NET
export DOTNET_ROOT=$HOME/.dotnet
export PATH=$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH

# Added by get-aspire-cli.sh
export PATH="$HOME/.aspire/bin:$PATH"

_process_aspire_logs() {
  local log_file="$1"

  awk '
  {
    line = $0
    
    # Skip empty lines
    if (line ~ /^[[:space:]]*$/) next
    
    # Aspire format: JSON is on lines that start with spaces and a number
    # Example: "      2: 2025-12-23T16:04:17.2830000Z {json here}"
    if (match(line, /^[[:space:]]+[0-9]+:[[:space:]]+[0-9T:.Z-]+[[:space:]]+(\{.*\})$/, arr)) {
      # Extract just the JSON part (after the timestamp)
      json_start = index(line, "{")
      if (json_start > 0) {
        json = substr(line, json_start)
        
        # Check if it'\''s our compact format
        if (match(json, /"ts":/) && match(json, /"level":/) && match(json, /"msg":/)) {
          process_compact_json(json)
        }
        # Or Microsoft'\''s format
        else if (match(json, /"Timestamp":/) && match(json, /"LogLevel":/) && match(json, /"Message":/)) {
          process_microsoft_json(json)
        }
      }
    }
  }

  function process_compact_json(json) {
    # Extract fields from compact format
    level = extract_field(json, "level")
    timestamp = extract_field(json, "ts")
    location = extract_field(json, "loc")
    message = extract_field(json, "msg")
    
    # Format timestamp as HH:MM:SS
    time = ""
    if (match(timestamp, /[0-9]{2}:[0-9]{2}:[0-9]{2}/)) {
      time = substr(timestamp, RSTART, RLENGTH)
    }
    
    # Truncate message for preview
    if (length(message) > 60) {
      message = substr(message, 1, 60) "..."
    }
    
    # Set color
    color = get_color(level)
    
    # Build display
    indicator = color level "\033[0m"
    display = indicator
    
    if (location != "") {
      display = display " \033[90m" location "\033[0m"
    }
    if (time != "") {
      display = display " " time
    }
    if (message != "") {
      display = display " " message
    }
    
    # Add padding
    padding = "                                                                                                                                                                  "
    
    # Output: display + padding + TAB + JSON
    print display padding "\t" json
  }

  function process_microsoft_json(json) {
    # Extract fields from Microsoft format
    level = extract_field(json, "LogLevel")
    timestamp = extract_field(json, "Timestamp")
    category = extract_field(json, "Category")
    message = extract_field(json, "Message")
    
    # Normalize level
    if (level == "Information") level = "INFO"
    else if (level == "Warning") level = "WARN"
    else if (level == "Error") level = "ERROR"
    else if (level == "Critical") level = "CRITICAL"
    else if (level == "Debug") level = "DEBUG"
    else if (level == "Trace") level = "TRACE"
    
    # Simplify category
    if (category != "") {
      split(category, parts, ".")
      category = parts[length(parts)]
    }
    
    # Format timestamp as HH:MM:SS
    time = ""
    if (match(timestamp, /[0-9]{2}:[0-9]{2}:[0-9]{2}/)) {
      time = substr(timestamp, RSTART, RLENGTH)
    }
    
    # Truncate message
    if (length(message) > 60) {
      message = substr(message, 1, 60) "..."
    }
    
    # Set color
    color = get_color(level)
    
    # Build display
    indicator = color level "\033[0m"
    display = indicator
    
    if (category != "") {
      display = display " \033[90m" category "\033[0m"
    }
    if (time != "") {
      display = display " " time
    }
    if (message != "") {
      display = display " " message
    }
    
    # Add padding
    padding = "                                                                                                                                                                  "
    
    print display padding "\t" json
  }

  function extract_field(json, field_name) {
    # Extract value of "field_name":"value"
    pattern = "\"" field_name "\":\"([^\"]+)\""
    if (match(json, pattern)) {
      start = index(json, "\"" field_name "\":\"") + length(field_name) + 4
      remaining = substr(json, start)
      end = index(remaining, "\"")
      return substr(remaining, 1, end - 1)
    }
    return ""
  }

  function get_color(level) {
    if (level == "CRITICAL") return "\033[1;31m"
    else if (level == "ERROR") return "\033[31m"
    else if (level == "WARN") return "\033[33m"
    else if (level == "INFO") return "\033[32m"
    else if (level == "DEBUG") return "\033[34m"
    else if (level == "TRACE") return "\033[90m"
    return "\033[32m"
  }
  ' "$log_file" | tac
}

asplog() {
  local log_dir="$HOME/Documents/Github/logs"
  
  pkill -f "tail -f.*-aspire\.log" 2>/dev/null
  
  local aspire_logs=$(find "$log_dir" -name "*-aspire.log" -type f 2>/dev/null)
  
  if [[ -z "$aspire_logs" ]]; then
    echo "No aspire logs found in $log_dir"
    return 1
  fi
  
  local selected_log=$(echo "$aspire_logs" | \
    sed "s|$log_dir/||" | \
    fzf \
      --prompt="Select aspire log file: " \
      --height=40% \
      --border \
      --reverse \
      --preview "tail -n 50 '$log_dir/{}'" \
      --preview-window "down,50%,wrap,border-top" \
      --header "Select aspire log to view")
  
  if [[ -z "$selected_log" ]]; then
    echo "No log file selected"
    return 1
  fi
  
  local log_file="$log_dir/$selected_log"
  export -f _process_aspire_logs
  
  trap "pkill -P $$; return" INT TERM
  
  while true; do
    clear
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📺 LIVE MODE: $selected_log"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Press 's' to search | 'q' to quit"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    tail -f "$log_file" 2>&1 | sed -u 's/\x1b\[[0-9;]*m//g' &
    local TAIL_PID=$!
    
    local key
    IFS= read -rsn1 key < /dev/tty
    
    kill -9 $TAIL_PID 2>/dev/null
    pkill -9 -P $TAIL_PID 2>/dev/null
    pkill -9 -f "tail -f $log_file" 2>/dev/null
    wait $TAIL_PID 2>/dev/null
    
    if [[ "$key" == "s" || "$key" == "S" ]]; then
      _process_aspire_logs "$log_file" | \
        fzf \
          --ansi \
          --no-sort \
          --layout=reverse \
          --border \
          --height=100% \
          --preview 'cut -f2 <<< {} | jq -C . 2>/dev/null || cut -f2 <<< {}' \
          --preview-window='down,70%,wrap,border-top' \
          --bind "ctrl-r:reload(_process_aspire_logs '$log_file')" \
          --bind "ctrl-/:toggle-preview" \
          --bind "alt-up:preview-half-page-up" \
          --bind "alt-down:preview-half-page-down" \
          --bind "ctrl-h:execute-silent(tmux select-pane -L)" \
          --bind "ctrl-j:execute-silent(tmux select-pane -D)" \
          --bind "ctrl-k:execute-silent(tmux select-pane -U)" \
          --bind "ctrl-l:execute-silent(tmux select-pane -R)" \
          --bind "enter:execute(
            tmp=\$(mktemp --suffix=.json)
            cut -f2 <<< {} | jq . > \$tmp 2>/dev/null || cut -f2 <<< {} > \$tmp
            nvim -c 'set ft=json' \$tmp
            rm -f \$tmp
          )" \
          --header "🔍 SEARCH MODE | ESC to return to live view | Ctrl-R: reload | Ctrl-/: toggle preview | Enter: open in nvim"
      
    elif [[ "$key" == "q" || "$key" == "Q" ]]; then
      echo ""
      echo "Exited log viewer"
      return 0
    fi
  done
}
