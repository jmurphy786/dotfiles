#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
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
echo ""
echo ""
fastfetch
echo ""
