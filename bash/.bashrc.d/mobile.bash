_process_mobile_logs() {
  local log_file="$1"

  awk 'BEGIN {
    collecting = 0
    ts_file = ""
    ts_line_num = ""
    ts_message = ""
    code_lines = ""
  }

  {
    line = $0
    # Remove ANSI
    gsub(/\x1b\[[0-9;]*[A-Za-z]/, "", line)
    gsub(/\x1b\[[0-9;]*m/, "", line)
    gsub(/\[[0-9]+[ABCDHJKST]/, "", line)
    gsub(/\[0J/, "", line)
    gsub(/\[144D/, "", line)
    gsub(/\[1A/, "", line)

    # Found an error
    if (line ~ /^[[:space:]]*ERROR[[:space:]]+(SyntaxError|TypeError|ReferenceError|Error):/) {
      # Output previous if exists
      if (collecting == 1 && code_lines != "") {
        indicator = "\033[31m●\033[0m \033[1mTS-ERROR\033[0m"
        if (ts_file != "" && ts_line_num != "") {
          display = indicator " \033[90m" ts_file ":" ts_line_num "\033[0m \033[33m" ts_message "\033[0m"
        } else {
          display = indicator " \033[33m" ts_message "\033[0m"
        }
        print display "\t" code_lines
      }
      
      # Start new
      collecting = 1
      code_lines = ""
      ts_file = ""
      ts_line_num = ""
      ts_message = ""
      
      # Extract full file path
      if (match(line, /\/[^:]+\.tsx?:/)) {
        ts_file = substr(line, RSTART, RLENGTH - 1)
      }
      
      # Extract message
      if (match(line, /\.tsx?: ([^(]+)/)) {
        msg_part = substr(line, RSTART + 6, RLENGTH - 6)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", msg_part)
        ts_message = msg_part
      }
      
      # Extract line number
      if (match(line, /\(([0-9]+):[0-9]+\)/)) {
        paren = substr(line, RSTART + 1, RLENGTH - 2)
        split(paren, nums, ":")
        ts_line_num = nums[1]
      }
      
      next
    }

    # If collecting, look for lines with |
    if (collecting == 1) {
      # Check if line has |
      if (line ~ /\|/) {
        # Extract content after |
        if (match(line, /\|(.*)$/)) {
          content = substr(line, RSTART + 1)
          # Add red highlight if line starts with >
          if (line ~ /^>/) {
            content = "\033[41m\033[37m" content "\033[0m"
          }
          # Append to code_lines
          if (code_lines != "") {
            code_lines = code_lines "\\n" content
          } else {
            code_lines = content
          }
        }
        next
      }
      
      # Check if we should stop collecting
      if (line ~ /^[[:space:]]*ERROR[[:space:]]+(SyntaxError|TypeError|ReferenceError|Error):/ ||
          line ~ /^›[[:space:]]+(Reloading|Bundling)/ ||
          line ~ /^(Android|iOS)[[:space:]]+(node_modules|Bundling)/ ||
          line ~ /^[[:space:]]*(LOG|ERROR|WARN|DEBUG|INFO)[[:space:]]+\{/) {
        
        # Output what we have
        if (code_lines != "") {
          indicator = "\033[31m●\033[0m \033[1mTS-ERROR\033[0m"
          if (ts_file != "" && ts_line_num != "") {
            display = indicator " \033[90m" ts_file ":" ts_line_num "\033[0m \033[33m" ts_message "\033[0m"
          } else {
            display = indicator " \033[33m" ts_message "\033[0m"
          }
          print display "\t" code_lines
        }
        
        # Reset
        collecting = 0
        code_lines = ""
        ts_file = ""
        ts_line_num = ""
        ts_message = ""
        
        # Fall through if JSON
        if (line !~ /^[[:space:]]*(LOG|ERROR|WARN|DEBUG|INFO)[[:space:]]+\{/) {
          next
        }
      } else {
        next
      }
    }

    # JSON processing
    if (line ~ /^[[:space:]]*$/) next
    
    json_content = ""
    if (match(line, /^[[:space:]]*(LOG|ERROR|WARN|DEBUG|INFO)[[:space:]]+\{/)) {
      json_start = index(line, "{")
      if (json_start > 0) {
        json_content = substr(line, json_start)
      }
    }
    
    if (json_content == "") next
    if (json_content !~ /"ts":/ || json_content !~ /"level":/ || json_content !~ /"msg":/) next
    
    level = ""
    if (match(json_content, /"level":"([^"]+)"/)) {
      level_start = index(json_content, "\"level\":\"") + 9
      level_end = index(substr(json_content, level_start), "\"")
      level = substr(json_content, level_start, level_end - 1)
    }
    if (level == "") next
    
    location = ""
    if (match(json_content, /"loc":"([^"]+)"/)) {
      loc_start = index(json_content, "\"loc\":\"") + 7
      loc_end = index(substr(json_content, loc_start), "\"")
      location = substr(json_content, loc_start, loc_end - 1)
      if (match(location, /:([0-9]+)$/)) {
        line_num = substr(location, RSTART + 1, RLENGTH - 1)
        location = "[Metro]:" line_num
      }
    }
    
    timestamp = ""
    if (match(json_content, /"ts":"([^"]+)"/)) {
      ts_start = index(json_content, "\"ts\":\"") + 6
      ts_end = index(substr(json_content, ts_start), "\"")
      full_ts = substr(json_content, ts_start, ts_end - 1)
      if (match(full_ts, /T([0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3})/)) {
        timestamp = substr(full_ts, RSTART + 1, RLENGTH - 1)
      }
    }
    
    message = ""
    if (match(json_content, /"msg":"([^"]+)"/)) {
      msg_start = index(json_content, "\"msg\":\"") + 7
      msg_end = index(substr(json_content, msg_start), "\"")
      message = substr(json_content, msg_start, msg_end - 1)
      if (length(message) > 60) {
        message = substr(message, 1, 60) "..."
      }
    }
    
    color = ""
    if (level == "ERROR") color = "\033[31m"
    else if (level == "WARN") color = "\033[33m"
    else if (level == "INFO") color = "\033[32m"
    else if (level == "DEBUG") color = "\033[34m"
    else if (level == "LOG") color = "\033[36m"
    
    indicator = color level "\033[0m"
    display = indicator
    if (location != "") display = display " \033[90m" location "\033[0m"
    if (timestamp != "") display = display " " timestamp
    if (message != "") display = display " " message
    
    padding = "                                                                                                                                                                  "
    print display padding "\t" json_content
  }
  
  END {
    if (collecting == 1 && code_lines != "") {
      indicator = "\033[31m●\033[0m \033[1mTS-ERROR\033[0m"
      if (ts_file != "" && ts_line_num != "") {
        display = indicator " \033[90m" ts_file ":" ts_line_num "\033[0m \033[33m" ts_message "\033[0m"
      } else {
        display = indicator " \033[33m" ts_message "\033[0m"
      }
      print display "\t" code_lines
    }
  }' "$log_file" | tac
}

mobilelog() {
  local log_dir="$HOME/Documents/Github/logs"
  pkill -f "tail -f.*mobile.*\.log" 2>/dev/null

  local mobile_logs=$(find "$log_dir" -name "*mobile*.log" -type f 2>/dev/null)
  if [[ -z "$mobile_logs" ]]; then
    echo "No mobile logs found in $log_dir"
    return 1
  fi

  local selected_log=$(echo "$mobile_logs" | \
    sed "s|$log_dir/||" | \
    fzf \
    --prompt="Select mobile log file: " \
    --height=40% \
    --border \
    --reverse \
    --preview "tail -n 50 '$log_dir/{}'" \
    --preview-window "down,50%,wrap,border-top" \
    --header "Select mobile log to view")

  if [[ -z "$selected_log" ]]; then
    echo "No log file selected"
    return 1
  fi

  local log_file="$log_dir/$selected_log"
  export -f _process_mobile_logs
  trap "pkill -P $$; return" INT TERM

  while true; do
    clear
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📱 LIVE MODE: $selected_log"
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
      _process_mobile_logs "$log_file" | \
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
        --preview-window "down,40%,wrap,border-top" \
        --bind "ctrl-r:reload(_process_mobile_logs '$log_file')" \
        --bind "ctrl-/:toggle-preview" \
        --bind "ctrl-e:reload(_process_mobile_logs '$log_file' | grep \"TS-ERROR\")" \
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
            file_path=\$(echo \$file_and_line | cut -d: -f1)
            line_num=\$(echo \$file_and_line | cut -d: -f2)
            
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
        --header "🔍 SEARCH | ESC: back | Ctrl-R: reload | Ctrl-E: errors only | Ctrl-/: preview | Enter: open"

    elif [[ "$key" == "q" || "$key" == "Q" ]]; then
      pkill -9 -P $$ 2>/dev/null
      trap - INT TERM
      echo ""
      echo "Exited log viewer"
      return 0
    fi
  done
}
