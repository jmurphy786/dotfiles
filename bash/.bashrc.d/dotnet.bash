# .NET
export DOTNET_ROOT=$HOME/.dotnet
export PATH=$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH

# Added by get-aspire-cli.sh
export PATH="$HOME/.aspire/bin:$PATH"

asprun() {
  local apphost_dir="$HOME/Documents/Github/aspire-dashboard/PortalsAPIs.AppHost"
  local log_dir="$HOME/Documents/Github/aspire-dashboard"
  local log_file="$log_dir/aspire-watch.log"

  mkdir -p "$log_dir"
  touch "$log_file"
  > "$log_file"

  echo "Starting Aspire with watch mode... (logs: $log_file)"
  dotnet watch run --project "$apphost_dir" 2>&1 | tee "$log_file"
}

_process_logs() {
  local log_file="$1"
  
  awk '
    /^(trace|debug|info|warn|error|crit): .*Resources\..*\[0\]$/ {
      match($0, /Resources\.([^[]+)/, arr)
      service = arr[1]
      getline
      
      # Store original line
      original = $0
      clean_msg = original
      
      # Extract the short time (HH:MM:SS format)
      match(original, /Z ([0-9]{2}:[0-9]{2}:[0-9]{2})/, t)
      time = t[1]
      
      # Detect actual log level
      actual_level = "info"
      if (match(original, /dbug/)) actual_level = "dbug"
      else if (match(original, /trce/)) actual_level = "trce"
      else if (match(original, /info/)) actual_level = "info"
      else if (match(original, /warn/)) actual_level = "warn"
      else if (match(original, /fail/)) actual_level = "fail"
      else if (match(original, /crit/)) actual_level = "crit"
      
      # Only clean if ANSI codes are present
      if (match(original, /\033\[/)) {
        # Remove line number, ISO timestamp, short time
        sub(/^[^:]*:[^Z]*Z [0-9]{2}:[0-9]{2}:[0-9]{2} /, "", clean_msg)
        # Strip ANSI codes
        gsub(/\033\[[0-9;]*m/, "", clean_msg)
        # Remove level prefix (dbug:, info:, etc)
        sub(/^(trce|dbug|info|warn|fail|crit): */, "", clean_msg)
      } else {
        # No ANSI codes, just remove prefix
        sub(/^[^:]*:[^Z]*Z /, "", clean_msg)
      }
      
      # Color indicator based on level
      if (actual_level == "crit") {
        indicator = "\033[1;31mCRIT\033[0m"
      } else if (actual_level == "fail") {
        indicator = "\033[31mERROR\033[0m"
      } else if (actual_level == "warn") {
        indicator = "\033[33mWARN\033[0m"
      } else if (actual_level == "info") {
        indicator = "\033[32mINFO\033[0m"
      } else if (actual_level == "dbug") {
        indicator = "\033[34mDEBUG\033[0m"
      } else if (actual_level == "trce") {
        indicator = "\033[90mTRACE\033[0m"
      } else {
        indicator = "\033[32mINFO\033[0m"
      }
      
      # Capitalize service name
      service_clean = toupper(substr(service, 1, 1)) substr(service, 2)
      
      print indicator " " service_clean " " time "\t" clean_msg
    }
  ' "$log_file" | tac
} 
asplog() {
  local latest="$HOME/Documents/Github/aspire-dashboard/aspire-watch.log" 
  if [[ ! -f "$latest" ]]; then
    echo "No Aspire logs found at $latest"
    return 1
  fi
  
  export -f _process_logs
  
  _process_logs "$latest" | \
    fzf \
      --ansi \
      --no-sort \
      --layout=reverse \
      --border \
      --height=80% \
      --delimiter='\t' \
      --with-nth=1 \
      --preview 'cut -f2 <<< {} | jq -C . 2>/dev/null || cut -f2 <<< {}' \
      --preview-window "down:70%:wrap" \
      --bind "ctrl-r:reload(_process_logs '$latest')" \
      --bind "ctrl-/:toggle-preview" \
      --bind "alt-up:preview-half-page-up" \
      --bind "alt-down:preview-half-page-down" \
      --bind "enter:execute(
        tmp=\$(mktemp --suffix=.json)
        cut -f2 <<< {} | jq . > \$tmp 2>/dev/null || cut -f2 <<< {} > \$tmp
        nvim -c 'set ft=json' \$tmp
        rm \$tmp
      )" \
      --header "Type to search | Ctrl-R: reload | Ctrl-/: toggle preview | Enter: open in nvim"
}

