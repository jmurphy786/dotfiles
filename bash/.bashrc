# ~/.bashrc

[[ $- != *i* ]] && return

# ============================================================================
# CORE CONFIGURATION (Always loaded)
# ============================================================================

alias ls='ls --color=auto'
alias ll='ls -lah'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# Better completion
if [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
fi

tmux-kill() {
  echo "Killing tmux server and cleaning nvim undo cache..."
  tmux kill-server

  # Clean up nvim undo files
  local undo_dir="$HOME/.local/state/nvim/undo"
  if [ -d "$undo_dir" ]; then
    rm -rf "$undo_dir"/*
    echo "✓ Cleared nvim undo cache: $undo_dir"
  fi

  # Alternative location (some systems use this)
  local cache_undo="$HOME/.cache/nvim/undo"
  if [ -d "$cache_undo" ]; then
    rm -rf "$cache_undo"/*
    echo "✓ Cleared nvim undo cache: $cache_undo"
  fi
}


# ============================================================================
# PATH CONFIGURATION
# ============================================================================

PROMPT_COMMAND=""

export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.tmuxifier/bin:$PATH"
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"
export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
export PATH="/mnt/c/Program Files/WezTerm:$PATH"  # ✅
source "$HOME/.bash_module_loader"
eval "$(tmuxifier init -)"
alias tdev='tmuxifier load-session dev'
alias tkill='tmux kill-server'
# ===========================================================================
# Scripts
# ===========================================================================

daily() {
  NOTES_DIR="$HOME/notes-work"
  DAILY_DIR="$NOTES_DIR/daily"
  TODAY=$(date +%Y-%m-%d)
  DAILY_FILE="$DAILY_DIR/$TODAY.md"

  mkdir -p "$DAILY_DIR"

  if [ ! -f "$DAILY_FILE" ]; then
    cat > "$DAILY_FILE" << EOF
# Daily Note - $(date '+%B %d, %Y')

## Tasks
- [ ] 

## Notes

## Links
- [[$(date -d 'yesterday' +%Y-%m-%d)]] (Yesterday)
EOF
  fi

  cd "$DAILY_DIR" && nvim "$DAILY_FILE"
}

_process_npm_logs() {
  local log_file="$1"

  awk '
  BEGIN {
    in_ts_error = 0
    ts_error_buffer = ""
    ts_file = ""
  }

{
  line = $0

  # Skip empty lines (unless in TS error)
  if (line ~ /^[[:space:]]*$/ && in_ts_error == 0) next

  # Remove the "»" prefix if present
  gsub(/^» */, "", line)

  # Start of TypeScript error block
  if (match(line, /ERROR\(TypeScript\)/)) {
    # If we were already collecting an error, output it first
    if (in_ts_error == 1 && ts_file != "") {
      indicator = "\033[31mTS-ERROR\033[0m"
      display = indicator " \033[90m" ts_file "\033[0m"
      print display "\t" ts_error_buffer
    }

    # Start new error
    in_ts_error = 1
    ts_error_buffer = line
    ts_file = ""
    next
  }

  # Collect TypeScript error lines
  if (in_ts_error == 1) {
    # Append with escaped newline for single-line storage
    ts_error_buffer = ts_error_buffer "\\n" line

    # Extract file path
    if (match(line, /FILE[[:space:]]+(.+\.tsx?):/, arr)) {
      full_path = line
      sub(/^[[:space:]]*FILE[[:space:]]+/, "", full_path)
      sub(/:.*$/, "", full_path)

      # Shorten path - get from apps/ or src/ onwards
      if (match(full_path, /(apps\/[^\/]+\/src\/.+)$/)) {
        ts_file = substr(full_path, RSTART, RLENGTH)
      } else if (match(full_path, /src\/.+$/)) {
        ts_file = substr(full_path, RSTART, RLENGTH)
      } else {
        # Just get filename
        split(full_path, parts, "/")
        ts_file = parts[length(parts)]
      }
  }

  # End of error block (empty line or summary line)
  if (line ~ /^[[:space:]]*$/ || 
    line ~ /\[TypeScript\] Found [0-9]+ error/ ||
    line ~ /Watching for file changes/) {

    # Output the collected error as single line
    if (ts_file != "") {
      indicator = "\033[31mTS-ERROR\033[0m"
      display = indicator " \033[90m" ts_file "\033[0m"
      print display "\t" ts_error_buffer
    }

    # Reset
    in_ts_error = 0
    ts_error_buffer = ""
    ts_file = ""
    next
  }
next
}

# Only process lines with explicit log level markers
level_found = 0
level = ""
color = ""
location = ""
message = line

if (match(line, /\[ERROR\]( [^[:space:]]+:[0-9]+)?/)) {
  level = "ERROR"
  color = "\033[31m"
  level_found = 1
  location_match = substr(line, RSTART, RLENGTH)
  gsub(/\[ERROR\] */, "", location_match)
  location = location_match
  sub(/\[ERROR\]( [^[:space:]]+:[0-9]+)? */, "", message)
} else if (match(line, /\[WARN\]( [^[:space:]]+:[0-9]+)?/)) {
  level = "WARN"
  color = "\033[33m"
  level_found = 1
  location_match = substr(line, RSTART, RLENGTH)
  gsub(/\[WARN\] */, "", location_match)
  location = location_match
  sub(/\[WARN\]( [^[:space:]]+:[0-9]+)? */, "", message)
} else if (match(line, /\[DEBUG\]( [^[:space:]]+:[0-9]+)?/)) {
  level = "DEBUG"
  color = "\033[34m"
  level_found = 1
  location_match = substr(line, RSTART, RLENGTH)
  gsub(/\[DEBUG\] */, "", location_match)
  location = location_match
  sub(/\[DEBUG\]( [^[:space:]]+:[0-9]+)? */, "", message)
} else if (match(line, /\[INFO\]( [^[:space:]]+:[0-9]+)?/)) {
  level = "INFO"
  color = "\033[32m"
  level_found = 1
  location_match = substr(line, RSTART, RLENGTH)
  gsub(/\[INFO\] */, "", location_match)
  location = location_match
  sub(/\[INFO\]( [^[:space:]]+:[0-9]+)? */, "", message)
} else if (match(line, /\[LOG\]( [^[:space:]]+:[0-9]+)?/)) {
  level = "LOG"
  color = "\033[36m"
  level_found = 1
  location_match = substr(line, RSTART, RLENGTH)
  gsub(/\[LOG\] */, "", location_match)
  location = location_match
  sub(/\[LOG\]( [^[:space:]]+:[0-9]+)? */, "", message)
}

# Skip lines that did not match any log level
if (level_found == 0) next

# Remove extra quotes from message
gsub(/^"/, "", message)
gsub(/"$/, "", message)

# Extract timestamp if present
time = ""
if (match(line, /[0-9]{1,2}:[0-9]{2}:[0-9]{2}/)) {
  time = substr(line, RSTART, RLENGTH)
}

# Format output
indicator = color level "\033[0m"

# Build display line
display = indicator
if (location != "") {
  display = display " \033[90m" location "\033[0m"
}
if (time != "") {
  display = display " " time
}

print display "\t" message
}

END {
  # Output any remaining TS error at end of file
  if (in_ts_error == 1 && ts_file != "") {
    indicator = "\033[31mTS-ERROR\033[0m"
    display = indicator " \033[90m" ts_file "\033[0m"
    print display "\t" ts_error_buffer
  }
}
' "$log_file" | tac
}

npmlog() {
  local log_file="$HOME/Documents/Github/logs/frontend.log"
  if [[ ! -f "$log_file" ]]; then
    echo "No npm logs found"
    return 1
  fi

  export -f _process_npm_logs

  _process_npm_logs "$log_file" | \
    fzf \
      --ansi \
      --no-sort \
      --layout=reverse \
      --border \
      --height=80% \
      --preview 'cut -f2 <<< {} | cut -c3- | sed "s/\\\\n/\n/g" | jq -C . 2>/dev/null || cut -f2 <<< {} | cut -c3- | sed "s/\\\\n/\n/g"' \
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
        tmp=\$(mktemp --suffix=.json)
        cut -f2 <<< {} | cut -c3- | sed 's/\\\\\\\\n/\n/g' | jq . > \$tmp 2>/dev/null || cut -f2 <<< {} | cut -c3- | sed 's/\\\\\\\\n/\n/g' > \$tmp
        nvim -c 'set ft=json' \$tmp
        rm -f \$tmp
      )" \
      --header "Type to search | Ctrl-R: reload | Ctrl-E: TS errors only | Ctrl-/: toggle preview"
}

# View mobile logs
mobilelog() {
  local log_file="$HOME/Documents/Github/logs/mobile.log"
  if [[ ! -f "$log_file" ]]; then
    echo "No mobile logs found"
    return 1
  fi

  cat "$log_file" | fzf \
    --ansi \
    --no-sort \
    --tac \
    --layout=reverse \
    --bind "ctrl-r:reload(cat '$log_file')" \
    --header "Mobile logs | Ctrl-R: reload"
  }

# ============================================================================
# STARTUP
# ============================================================================

#fastfetch

alias bat='batcat'
