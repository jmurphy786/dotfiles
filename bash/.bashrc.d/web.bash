_process_npm_logs() {
  local log_file="$1"

  awk '
  BEGIN {
    in_ts_error = 0
    ts_error_buffer = ""
    ts_file = ""
    ts_line_num = ""
  }

{
  line = $0

  # Skip empty lines (unless in TS error)
  if (line ~ /^[[:space:]]*$/ && in_ts_error == 0) next

  # Remove the "»" prefix
  gsub(/^» */, "", line)

  # ============================================================================
  # TypeScript Error Handling
  # ============================================================================
  
  # Start of TypeScript error block
  if (match(line, /ERROR\(TypeScript\)/)) {
    # If we were already collecting an error, output it first
    if (in_ts_error == 1 && ts_file != "") {
      indicator = "\033[31m●\033[0m \033[1mTS-ERROR\033[0m"
      if (ts_line_num != "") {
        display = indicator " \033[90m" ts_file ":" ts_line_num "\033[0m"
      } else {
        display = indicator " \033[90m" ts_file "\033[0m"
      }
      print display "\t" ts_error_buffer
    }

    # Start new error
    in_ts_error = 1
    ts_error_buffer = line
    ts_file = ""
    ts_line_num = ""
    next
  }

  # Collect TypeScript error lines
  if (in_ts_error == 1) {
    # Highlight the error line (starts with >)
    if (line ~ /^[[:space:]]*>/) {
      ts_error_buffer = ts_error_buffer "\\n\033[41m\033[37m" line "\033[0m"
    } else {
      ts_error_buffer = ts_error_buffer "\\n" line
    }

    # Extract file path and line number from FILE line
    if (match(line, /FILE[[:space:]]+(.+\.tsx?):/)) {
      full_path = line
      sub(/^[[:space:]]*FILE[[:space:]]+/, "", full_path)
      
      # Extract line number (e.g., :23:7 -> 23)
      if (match(full_path, /:([0-9]+):[0-9]+$/)) {
        line_part = substr(full_path, RSTART + 1, RLENGTH - 1)
        split(line_part, nums, ":")
        ts_line_num = nums[1]
      }
      
      # Remove line/col numbers from path
      sub(/:[0-9]+:[0-9]+$/, "", full_path)
      ts_file = full_path
    }

    # End of error block
    if (line ~ /^[[:space:]]*$/ || 
        line ~ /\[TypeScript\] Found [0-9]+ error/ ||
        line ~ /Watching for file changes/) {
      if (ts_file != "") {
        indicator = "\033[31m●\033[0m \033[1mTS-ERROR\033[0m"
        if (ts_line_num != "") {
          display = indicator " \033[90m" ts_file ":" ts_line_num "\033[0m"
        } else {
          display = indicator " \033[90m" ts_file "\033[0m"
        }
        print display "\t" ts_error_buffer
      }
      in_ts_error = 0
      ts_error_buffer = ""
      ts_file = ""
      ts_line_num = ""
      next
    }
    next
  }

  # ============================================================================
  # JSON Log Handling
  # ============================================================================
  
  # Only process JSON logs
  if (line !~ /^\s*\{.*"ts".*"level".*"msg".*\}/) next
  
  json_content = line
  gsub(/^[[:space:]]+/, "", json_content)
  
  # Extract level
  level = ""
  if (match(json_content, /"level":"([^"]+)"/)) {
    level_start = index(json_content, "\"level\":\"") + 9
    level_end = index(substr(json_content, level_start), "\"")
    level = substr(json_content, level_start, level_end - 1)
  }
  
  # Extract location
  location = ""
  if (match(json_content, /"loc":"([^"]+)"/)) {
    loc_start = index(json_content, "\"loc\":\"") + 7
    loc_end = index(substr(json_content, loc_start), "\"")
    location = substr(json_content, loc_start, loc_end - 1)
  }
  
  # Extract and format timestamp as HH:MM:SS
  timestamp = ""
  if (match(json_content, /"ts":"([^"]+)"/)) {
    ts_start = index(json_content, "\"ts\":\"") + 6
    ts_end = index(substr(json_content, ts_start), "\"")
    full_ts = substr(json_content, ts_start, ts_end - 1)
    # Extract HH:MM:SS from ISO format (2025-12-23T14:47:00.842Z)
    if (match(full_ts, /T([0-9]{2}:[0-9]{2}:[0-9]{2})/)) {
      timestamp = substr(full_ts, RSTART + 1, RLENGTH - 1)
    }
  }
  
  # Extract message
  message = ""
  if (match(json_content, /"msg":"([^"]+)"/)) {
    msg_start = index(json_content, "\"msg\":\"") + 7
    msg_end = index(substr(json_content, msg_start), "\"")
    message = substr(json_content, msg_start, msg_end - 1)
    
    # Truncate for preview if too long
    if (length(message) > 60) {
      message = substr(message, 1, 60) "..."
    }
  }
  
  # Set color
  color = ""
  if (level == "ERROR") color = "\033[31m"
  else if (level == "WARN") color = "\033[33m"
  else if (level == "INFO") color = "\033[32m"
  else if (level == "DEBUG") color = "\033[34m"
  else if (level == "LOG") color = "\033[36m"
  
  # Build display line
  indicator = color level "\033[0m"
  display = indicator
  
  if (location != "") {
    display = display " \033[90m" location "\033[0m"
  }
  if (timestamp != "") {
    display = display " " timestamp
  }
  if (message != "") {
    display = display " " message
  }
  
  # Add padding for alignment
  padding = "                                                                                                                                                                  "
  
  print display padding "\t" json_content
}

END {
  # Output any remaining TS error at end of file
  if (in_ts_error == 1 && ts_file != "") {
    indicator = "\033[31m●\033[0m \033[1mTS-ERROR\033[0m"
    if (ts_line_num != "") {
      display = indicator " \033[90m" ts_file ":" ts_line_num "\033[0m"
    } else {
      display = indicator " \033[90m" ts_file "\033[0m"
    }
    print display "\t" ts_error_buffer
  }
}
' "$log_file" | tac
}


weblog() {
  local log_dir="$HOME/Documents/Github/logs"
  pkill -f "tail -f.*web.*\.log" 2>/dev/null
  
  local web_logs=$(find "$log_dir" -name "*web*.log" -type f 2>/dev/null)
  
  if [[ -z "$web_logs" ]]; then
    echo "No web logs found in $log_dir"
    return 1
  fi
  
  local selected_log=$(echo "$web_logs" | \
    sed "s|$log_dir/||" | \
    fzf \
    --prompt="Select web log file: " \
    --height=40% \
    --border \
    --reverse \
    --preview "tail -n 50 '$log_dir/{}'" \
    --preview-window "down,50%,wrap,border-top" \
    --header "Select web log to view")
  
  if [[ -z "$selected_log" ]]; then
    echo "No log file selected"
    return 1
  fi
  
  local log_file="$log_dir/$selected_log"
  export -f _process_npm_logs
  
  trap "pkill -P $$; return" INT TERM
  
  while true; do
    clear
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌐 LIVE MODE: $selected_log"
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
      _process_npm_logs "$log_file" | \
        fzf \
        --ansi \
        --no-sort \
        --layout=reverse \
        --border \
        --height=100% \
        --delimiter='\t' \
        --preview 'if echo {1} | grep -q "TS-ERROR"; then
          echo {2} | xargs -0 echo -e | bat --style=plain --color=always -l typescript 2>/dev/null || echo {2} | xargs -0 echo -e
        else
          echo {2} | jq -C . 2>/dev/null || echo {2}
        fi' \
        --preview-window "down,70%,wrap,border-top" \
        --bind "ctrl-r:reload(_process_npm_logs '$log_file')" \
        --bind "ctrl-/:toggle-preview" \
        --bind "ctrl-e:reload(_process_npm_logs '$log_file' | grep \"TS-ERROR\")" \
        --bind "alt-up:preview-half-page-up" \
        --bind "alt-down:preview-half-page-down" \
        --bind "ctrl-h:execute-silent(tmux select-pane -L)" \
        --bind "ctrl-j:execute-silent(tmux select-pane -D)" \
        --bind "ctrl-k:execute-silent(tmux select-pane -U)" \
        --bind "ctrl-l:execute-silent(tmux select-pane -R)" \
        --bind "enter:execute(
          if echo {1} | grep -q \"TS-ERROR\"; then
            # Extract full file path and line number from TS-ERROR display
            file_and_line=\$(echo {1} | grep -oP '/[^ ]+\.tsx?:[0-9]+' | head -1)
            file_path=\$(echo \$file_and_line | cut -d: -f1-10 | rev | cut -d: -f2- | rev)
            line_num=\$(echo \$file_and_line | rev | cut -d: -f1 | rev)
            
            if [[ -f \"\$file_path\" ]]; then
              nvim \"+\$line_num\" \"\$file_path\"
            else
              echo \"File not found: \$file_path\"
              read -n 1
            fi
          else
            # JSON log - view in nvim
            tmp=\$(mktemp --suffix=.json)
            echo {2} | jq . > \$tmp 2>/dev/null || echo {2} > \$tmp
            nvim -c 'set ft=json' \$tmp
            rm -f \$tmp
          fi
        )" \
        --header "🔍 SEARCH MODE | ESC: back | Ctrl-R: reload | Ctrl-E: TS errors | Ctrl-/: preview | Enter: open"
    
    elif [[ "$key" == "q" || "$key" == "Q" ]]; then
      pkill -9 -P $$ 2>/dev/null
      trap - INT TERM
      echo ""
      echo "Exited log viewer"
      return 0
    fi
  done
}
