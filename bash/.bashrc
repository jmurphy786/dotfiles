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

export PATH="$HOME/.tmuxifier/bin:$PATH"
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"
export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
export PATH="/mnt/c/Program Files/WezTerm:$PATH"  # ✅
source "$HOME/.bash_module_loader"
eval "$(tmuxifier init -)"

# ============================================================================
# STARTUP
# ============================================================================

echo ""
echo ""
fastfetch
echo ""

alias bat='batcat'
