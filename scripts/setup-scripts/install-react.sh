#!/bin/bash
# ============================================================================
# REACT/NODE.JS DEVELOPMENT ENVIRONMENT SETUP
# ============================================================================
# This script installs Node.js, npm, yarn, and React development tools
# Safe to run multiple times (idempotent)

set -e  # Exit on error

SCRIPT_NAME="React/Node.js Setup"
LOG_FILE="$HOME/setup-scripts/logs/react-install-$(date +%Y%m%d-%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create log directory
mkdir -p "$HOME/setup-scripts/logs"

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ============================================================================
# NVM (Node Version Manager) INSTALLATION
# ============================================================================

install_nvm() {
    log "Installing NVM (Node Version Manager)..."
    
    if [[ -d "$HOME/.nvm" ]]; then
        info "NVM already installed at ~/.nvm"
        return 0
    fi
    
    # Download and install NVM
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    
    # Load NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    log "✓ NVM installed"
}

# ============================================================================
# NODE.JS INSTALLATION
# ============================================================================

install_nodejs() {
    log "Installing Node.js..."
    
    # Load NVM if not already loaded
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if command_exists node; then
        info "Node.js already installed: $(node --version)"
        
        read -p "Do you want to install the latest LTS version? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    # Install latest LTS version
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'
    
    log "✓ Node.js installed: $(node --version)"
    log "✓ npm installed: $(npm --version)"
}

# ============================================================================
# PACKAGE MANAGERS
# ============================================================================

install_yarn() {
    log "Installing Yarn..."
    
    if command_exists yarn; then
        info "Yarn already installed: $(yarn --version)"
        return 0
    fi
    
    npm install -g yarn
    
    log "✓ Yarn installed: $(yarn --version)"
}

install_pnpm() {
    log "Installing pnpm..."
    
    if command_exists pnpm; then
        info "pnpm already installed: $(pnpm --version)"
        return 0
    fi
    
    npm install -g pnpm
    
    log "✓ pnpm installed: $(pnpm --version)"
}

# ============================================================================
# REACT & DEVELOPMENT TOOLS
# ============================================================================

install_react_tools() {
    log "Installing React development tools..."
    
    local tools=(
        "create-react-app"
        "vite"
        "@vitejs/app"
    )
    
    for tool in "${tools[@]}"; do
        if npm list -g "$tool" >/dev/null 2>&1; then
            info "$tool already installed"
        else
            log "Installing $tool..."
            npm install -g "$tool" 2>&1 | tee -a "$LOG_FILE"
        fi
    done
    
    log "✓ React tools installed"
}

# ============================================================================
# GLOBAL NPM PACKAGES
# ============================================================================

install_global_packages() {
    log "Installing useful global npm packages..."
    
    local packages=(
        "typescript"
        "tsx"
        "nodemon"
        "pm2"
        "serve"
        "http-server"
        "eslint"
        "prettier"
    )
    
    for package in "${packages[@]}"; do
        if npm list -g "$package" >/dev/null 2>&1; then
            info "$package already installed"
        else
            log "Installing $package..."
            npm install -g "$package" 2>&1 | tee -a "$LOG_FILE"
        fi
    done
    
    log "✓ Global packages installed"
}

# ============================================================================
# OPTIONAL: VISUAL STUDIO CODE EXTENSIONS
# ============================================================================

install_vscode_extensions() {
    if ! command_exists code; then
        info "VS Code not installed, skipping extensions"
        return 0
    fi
    
    read -p "Do you want to install recommended VS Code extensions? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Skipping VS Code extensions"
        return 0
    fi
    
    log "Installing VS Code extensions for React/Node.js..."
    
    local extensions=(
        "dsznajder.es7-react-js-snippets"
        "dbaeumer.vscode-eslint"
        "esbenp.prettier-vscode"
        "formulahendry.auto-rename-tag"
        "bradlc.vscode-tailwindcss"
        "PKief.material-icon-theme"
        "naumovs.color-highlight"
    )
    
    for ext in "${extensions[@]}"; do
        if code --list-extensions | grep -q "$ext"; then
            info "$ext already installed"
        else
            log "Installing $ext..."
            code --install-extension "$ext" 2>&1 | tee -a "$LOG_FILE"
        fi
    done
    
    log "✓ VS Code extensions installed"
}

# ============================================================================
# CREATE NVM MODULE FOR BASH
# ============================================================================

create_nvm_module() {
    log "Creating NVM module for bash..."
    
    local module_file="$HOME/.bashrc.d/nvm.bash"
    
    if [[ -f "$module_file" ]]; then
        info "NVM module already exists at $module_file"
        return 0
    fi
    
    mkdir -p "$HOME/.bashrc.d"
    
    cat > "$module_file" << 'EOF'
# ============================================================================
# NODE.JS / NVM CONFIGURATION
# ============================================================================
# This module provides Node.js development environment via NVM

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Auto-load .nvmrc when changing directories
autoload_nvmrc() {
  if [[ -f .nvmrc && -r .nvmrc ]]; then
    nvm use
  fi
}
cd() { builtin cd "$@" && autoload_nvmrc; }
EOF
    
    log "✓ NVM module created at $module_file"
    info "Enable it with: bash_enable_module nvm"
}

# ============================================================================
# DEPENDENCIES
# ============================================================================

install_dependencies() {
    log "Installing system dependencies..."
    
    sudo apt update
    sudo apt install -y \
        curl \
        wget \
        git \
        build-essential \
        libssl-dev
    
    log "✓ Dependencies installed"
}

# ============================================================================
# ENVIRONMENT VERIFICATION
# ============================================================================

verify_installation() {
    log "Verifying installation..."
    
    # Load NVM for verification
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    local all_ok=true
    
    # Check NVM
    if command_exists nvm; then
        log "✓ NVM: $(nvm --version)"
    else
        error "✗ NVM not found"
        all_ok=false
    fi
    
    # Check Node.js
    if command_exists node; then
        log "✓ Node.js: $(node --version)"
    else
        error "✗ Node.js not found"
        all_ok=false
    fi
    
    # Check npm
    if command_exists npm; then
        log "✓ npm: $(npm --version)"
    else
        error "✗ npm not found"
        all_ok=false
    fi
    
    # Check yarn
    if command_exists yarn; then
        log "✓ Yarn: $(yarn --version)"
    else
        warn "✗ Yarn not found"
    fi
    
    # Check pnpm
    if command_exists pnpm; then
        log "✓ pnpm: $(pnpm --version)"
    else
        warn "✗ pnpm not found"
    fi
    
    # Check React tools
    if command_exists vite; then
        log "✓ Vite installed"
    else
        warn "✗ Vite not found"
    fi
    
    if [[ "$all_ok" == true ]]; then
        log "✓✓✓ React/Node.js environment setup complete! ✓✓✓"
        echo ""
        info "Please run: source ~/.bashrc"
        info "Or open a new terminal to load NVM"
        echo ""
        info "Don't forget to enable the nvm module:"
        echo "  bash_enable_module nvm"
    else
        error "Some components failed to install. Check the log: $LOG_FILE"
        return 1
    fi
}

# ============================================================================
# MAIN INSTALLATION FLOW
# ============================================================================

main() {
    log "========================================"
    log "  $SCRIPT_NAME"
    log "========================================"
    log "Log file: $LOG_FILE"
    echo ""
    
    # Check if running on Linux
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        error "This script is designed for Linux. Detected: $OSTYPE"
        exit 1
    fi
    
    # Install in order
    install_dependencies
    install_nvm
    install_nodejs
    install_yarn
    install_pnpm
    install_react_tools
    install_global_packages
    install_vscode_extensions
    create_nvm_module
    
    echo ""
    verify_installation
    
    echo ""
    log "Installation log saved to: $LOG_FILE"
    
    echo ""
    info "Useful commands:"
    echo "  nvm ls                  # List installed Node versions"
    echo "  nvm install 20          # Install Node.js v20"
    echo "  nvm use 20              # Use Node.js v20"
    echo "  npm create vite@latest  # Create new Vite project"
    echo "  npx create-react-app    # Create new React app"
}

# Run main installation
main "$@"
