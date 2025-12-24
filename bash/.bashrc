# ~/.bashrc

# Global log viewer cleanup
_cleanup_log_viewers() {
  # Kill all tail processes reading from logs directory
  pkill -f "tail -f.*Documents/Github/logs"

  # Kill any sed processes in the pipeline
  pkill -f "sed -u.*x1b"

  # Wait a moment for cleanup
  sleep 0.1
}

# Cleanup on shell exit
trap _cleanup_log_viewers EXIT

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



# ============================================================================
# STARTUP
# ============================================================================

#fastfetch

alias bat='batcat'
