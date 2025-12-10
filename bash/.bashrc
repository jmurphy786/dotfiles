#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
#PS1='[\u@\h \W]\$ '
PS1='[\u@\h \W]\$ '
source /usr/share/fzf/key-bindings.bash
source /usr/share/fzf/completion.bash

# Comprehensive .fdignore
cat > ~/.fdignore << 'EOF'
.git/
node_modules/
.cache/
.cargo/
.rustup/
.npm/
.local/share/
.mozilla/
__pycache__/
*.pyc
.venv/
venv/
target/
dist/
build/
.wine/
.steam/
EOF

# Better completion
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

# fzf integration
[ -f ~/.fzf.bash ] && source ~/.fzf.bash


# Use fd for fzf completion (respects .fdignore)
_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "$1"
}

_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "$1"
}

export FZF_COMPLETION_TRIGGER='**'

alias ls='ls --color=auto'
alias ll='ls -lah'

# Simple and effective
export FZF_DEFAULT_COMMAND='fd --type f  --hidden --follow --max-depth 4'

export FZF_CTRL_T_COMMAND='fd --type f --hidden --follow --max-depth 4'

export FZF_DEFAULT_OPTS='
  --height 40%
  --layout=reverse
  --border
  --preview "bat --style=numbers --color=always {} 2>/dev/null || cat {}"
  --bind "ctrl-/:toggle-preview"'

# fzf file/folder autocomplete with Ctrl+G
__fzf_file_widget() {
    local selected
    local current_input="${READLINE_LINE:0:$READLINE_POINT}"
    
    # Extract the path being typed (last token)
    local path_prefix=$(echo "$current_input" | grep -oE '[^ ]*$')
    
    # Determine directory to search
    local search_dir="."
    if [[ "$path_prefix" == */* ]]; then
        search_dir="${path_prefix%/*}"
        [[ -z "$search_dir" ]] && search_dir="/"
    fi
    
    # Only proceed if directory exists
    if [[ -d "$search_dir" ]]; then
        # Get files/folders, show only basenames in fzf
        selected=$(cd "$search_dir" 2>/dev/null && find . -maxdepth 1 -mindepth 1 -printf '%P\n' 2>/dev/null | \
            fzf --height=40% --reverse --prompt="Select> ")
        
        if [[ -n "$selected" ]]; then
            # Build full path
            local full_path="$search_dir/$selected"
            [[ "$search_dir" == "." ]] && full_path="$selected"
            
            # Add trailing slash for directories
            [[ -d "$full_path" ]] && full_path="$full_path/"
            
            # Replace the path prefix with the selection
            local before_path="${current_input%$path_prefix}"
            READLINE_LINE="${before_path}${full_path}"
            READLINE_POINT=${#READLINE_LINE}
        fi
    fi
}
PROMPT_COMMAND=""

# Add to your shell config (~/.bashrc, ~/.zshrc, etc.)
export PATH="$HOME/.tmuxifier/bin:$PATH"
eval "$(tmuxifier init -)"

# Bind Ctrl+G to the function
bind -x '"\C-g": __fzf_file_widget'
echo ""
echo ""
fastfetch
echo ""

