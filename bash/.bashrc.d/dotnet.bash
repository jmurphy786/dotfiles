# .NET
export DOTNET_ROOT=$HOME/.dotnet
export PATH=$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH

# Added by get-aspire-cli.sh
export PATH="$HOME/.aspire/bin:$PATH"

_process_aspire_logs() {
  local log_file="$1"

  awk '
  BEGIN {
    in_activity = 0
    activity_lines = ""
  }
  {
    # Extract content after timestamp
    if (match($0, /[0-9]+:[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9TZ:.+-]+[[:space:]]+/)) {
      content = substr($0, RSTART + RLENGTH)
    } else {
      next
    }
    
    # Start of activity
    if (content ~ /^Activity\.TraceId:/) {
      if (in_activity) {
        process_activity(activity_lines)
      }
      in_activity = 1
      activity_lines = content
      next
    }
    
    # In activity
    if (in_activity) {
      # Empty content = end of activity
      if (content ~ /^[[:space:]]*$/) {
        process_activity(activity_lines)
        in_activity = 0
        activity_lines = ""
      } else {
        activity_lines = activity_lines "\n" content
      }
    }
  }
  
  END {
    if (in_activity) {
      process_activity(activity_lines)
    }
  }

  function process_activity(text) {
    # Init
    trace_id = span_id = parent_span_id = display_name = kind = ""
    start_time = duration = trace_flags = source = service_name = ""
    delete tags
    tag_count = 0
    in_tags = 0
    
    n = split(text, lines, "\n")
    
    for (i = 1; i <= n; i++) {
      line = lines[i]
      
      # Check for Activity.Tags marker
      if (line == "Activity.Tags:") {
        in_tags = 1
        continue
      }
      
      # If in tags mode, collect tags until we hit a non-tag line
      if (in_tags) {
        if (index(line, ":") > 0 && line !~ /^Activity\./ && line !~ /^Instrumentation/ && line !~ /^Resource/) {
          # This is a tag
          colon = index(line, ":")
          k = substr(line, 1, colon - 1)
          v = substr(line, colon + 1)
          # Trim
          gsub(/^[[:space:]]+/, "", k)
          gsub(/[[:space:]]+$/, "", k)
          gsub(/^[[:space:]]+/, "", v)
          gsub(/[[:space:]]+$/, "", v)
          # Escape
          gsub(/\\/, "\\\\", v)
          gsub(/"/, "\\\"", v)
          tags[k] = v
          tag_count++
          continue
        } else {
          # Not a tag anymore, exit tags mode
          in_tags = 0
        }
      }
      
      # Parse activity properties
      if (line ~ /^Activity\.TraceId:/) {
        gsub(/^Activity\.TraceId:[[:space:]]*/, "", line)
        trace_id = line
      }
      else if (line ~ /^Activity\.SpanId:/) {
        gsub(/^Activity\.SpanId:[[:space:]]*/, "", line)
        span_id = line
      }
      else if (line ~ /^Activity\.ParentSpanId:/) {
        gsub(/^Activity\.ParentSpanId:[[:space:]]*/, "", line)
        parent_span_id = line
      }
      else if (line ~ /^Activity\.DisplayName:/) {
        gsub(/^Activity\.DisplayName:[[:space:]]*/, "", line)
        display_name = line
      }
      else if (line ~ /^Activity\.Kind:/) {
        gsub(/^Activity\.Kind:[[:space:]]*/, "", line)
        kind = line
      }
      else if (line ~ /^Activity\.StartTime:/) {
        gsub(/^Activity\.StartTime:[[:space:]]*/, "", line)
        start_time = line
      }
      else if (line ~ /^Activity\.Duration:/) {
        gsub(/^Activity\.Duration:[[:space:]]*/, "", line)
        duration = line
      }
      else if (line ~ /^Activity\.TraceFlags:/) {
        gsub(/^Activity\.TraceFlags:[[:space:]]*/, "", line)
        trace_flags = line
      }
      else if (line ~ /^Name:/) {
        gsub(/^Name:[[:space:]]*/, "", line)
        source = line
      }
      else if (line ~ /^service\.name:/) {
        gsub(/^service\.name:[[:space:]]*/, "", line)
        service_name = line
      }
    }
    
    # Build tags JSON
    tags_json = ""
    for (k in tags) {
      if (tags_json != "") tags_json = tags_json ", "
      tags_json = tags_json "\"" k "\": \"" tags[k] "\""
    }
    
    # Build JSON
    j = "{"
    j = j "\"TraceId\":\"" trace_id "\""
    j = j ",\"SpanId\":\"" span_id "\""
    if (parent_span_id != "") j = j ",\"ParentSpanId\":\"" parent_span_id "\""
    j = j ",\"DisplayName\":\"" display_name "\""
    j = j ",\"Kind\":\"" kind "\""
    j = j ",\"StartTime\":\"" start_time "\""
    j = j ",\"Duration\":\"" duration "\""
    j = j ",\"TraceFlags\":\"" trace_flags "\""
    if (source != "") j = j ",\"Source\":\"" source "\""
    if (service_name != "") j = j ",\"ServiceName\":\"" service_name "\""
    if (tags_json != "") j = j ",\"Tags\":{" tags_json "}"
    j = j "}"
    
    # Display
    sc = ""
    if ("http.response.status_code" in tags) sc = tags["http.response.status_code"]
    
    col = "\033[36m"
    if (sc >= 500) col = "\033[31m"
    else if (sc >= 400) col = "\033[33m"
    else if (sc >= 200) col = "\033[32m"
    
    tm = ""
    if (match(start_time, /T[0-9]{2}:[0-9]{2}:[0-9]{2}/)) {
      tm = substr(start_time, RSTART + 1, 8)
    }
    
    d = col "TRACE\033[0m \033[35m" kind "\033[0m"
    if (display_name != "") {
      nm = display_name
      if (length(nm) > 45) nm = substr(nm, 1, 45) "..."
      d = d " \033[1m" nm "\033[0m"
    }
    if (sc != "") d = d " \033[90m[" sc "]\033[0m"
    if (duration != "") d = d " \033[90m" duration "\033[0m"
    if (tm != "") d = d " " tm
    if (tag_count > 0) d = d " \033[90m(" tag_count " tags)\033[0m"
    
    pad = "                                                                                                                                                                  "
    print d pad "\t" j
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
          --bind "enter:execute(
            tmp=\$(mktemp --suffix=.json)
            cut -f2 <<< {} | jq . > \$tmp 2>/dev/null || cut -f2 <<< {} > \$tmp
            nvim -c 'set ft=json' \$tmp
            rm -f \$tmp
          )" \
          --header "🔍 SEARCH | ESC: live | Ctrl-R: reload | Ctrl-/: preview | Enter: nvim"
      
    elif [[ "$key" == "q" || "$key" == "Q" ]]; then
      echo ""
      echo "Exited log viewer"
      return 0
    fi
  done
}
