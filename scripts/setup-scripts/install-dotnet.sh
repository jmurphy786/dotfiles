#!/bin/bash
# ============================================================================
# .NET DEVELOPMENT ENVIRONMENT SETUP
# ============================================================================
# This script installs .NET SDK, Aspire, and related tools
# Safe to run multiple times (idempotent)

set -e  # Exit on error

SCRIPT_NAME=".NET Setup"
LOG_FILE="$HOME/setup-scripts/logs/dotnet-install-$(date +%Y%m%d-%H%M%S).log"

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
# .NET SDK INSTALLATION
# ============================================================================

install_dotnet_sdk() {
    log "Installing .NET SDK..."
    
    if command_exists dotnet; then
        info ".NET already installed: $(dotnet --version)"
        
        read -p "Do you want to update/reinstall? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    log "Adding Microsoft package repository..."
    
    # Get Ubuntu version
    ubuntu_version=$(lsb_release -rs)
    
    # Download Microsoft package signing key
    wget https://packages.microsoft.com/config/ubuntu/${ubuntu_version}/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
    sudo dpkg -i /tmp/packages-microsoft-prod.deb
    rm /tmp/packages-microsoft-prod.deb
    
    # Install .NET SDK
    sudo apt-get update
    sudo apt-get install -y dotnet-sdk-10.0
    
    log "✓ .NET SDK installed: $(dotnet --version)"
}

# ============================================================================
# .NET TOOLS
# ============================================================================

install_dotnet_tools() {
    log "Installing .NET global tools..."
    
    # EF Core tools
    if ! dotnet tool list -g | grep -q "dotnet-ef"; then
        log "Installing Entity Framework Core tools..."
        dotnet tool install --global dotnet-ef
    else
        info "EF Core tools already installed"
    fi
    
    # Aspire workload
    if ! dotnet workload list | grep -q "aspire"; then
        log "Installing Aspire workload..."
        dotnet workload install aspire
    else
        info "Aspire workload already installed"
    fi
    
    log "✓ .NET tools installed"
}

# ============================================================================
# ASPIRE CLI
# ============================================================================

install_aspire_cli() {
    log "Installing Aspire CLI..."
    
    # Check if aspire is already in PATH
    if command_exists aspire; then
        info "Aspire CLI already installed"
        return 0
    fi
    
    # Download and run the Aspire CLI installer
    curl -sSL https://dot.net/v1/aspire-install.sh | bash
    
    log "✓ Aspire CLI installed"
}

# ============================================================================
# DEVELOPMENT CERTIFICATES
# ============================================================================

setup_dev_certificates() {
    log "Setting up development certificates..."
    
    # Trust the .NET development certificate
    dotnet dev-certs https --trust 2>&1 | tee -a "$LOG_FILE"
    
    log "✓ Development certificates configured"
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
    
    log "Installing VS Code extensions for .NET..."
    
    local extensions=(
        "ms-dotnettools.csdevkit"
        "ms-dotnettools.csharp"
        "ms-dotnettools.vscode-dotnet-runtime"
        "visualstudioexptteam.vscodeintellicode"
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
# DEPENDENCIES
# ============================================================================

install_dependencies() {
    log "Installing system dependencies..."
    
    sudo apt update
    sudo apt install -y \
        wget \
        curl \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release
    
    log "✓ Dependencies installed"
}

# ============================================================================
# ENVIRONMENT VERIFICATION
# ============================================================================

verify_installation() {
    log "Verifying installation..."
    
    local all_ok=true
    
    # Check .NET
    if command_exists dotnet; then
        log "✓ .NET SDK: $(dotnet --version)"
        
        # Check workloads
        if dotnet workload list | grep -q "aspire"; then
            log "✓ Aspire workload installed"
        else
            warn "✗ Aspire workload not found"
        fi
    else
        error "✗ .NET SDK not found"
        all_ok=false
    fi
    
    # Check tools
    if dotnet tool list -g | grep -q "dotnet-ef"; then
        log "✓ EF Core tools installed"
    else
        warn "✗ EF Core tools not found"
    fi
    
    # Check Aspire CLI
    if command_exists aspire; then
        log "✓ Aspire CLI installed"
    else
        warn "✗ Aspire CLI not in PATH (may need to reload shell)"
    fi
    
    if [[ "$all_ok" == true ]]; then
        log "✓✓✓ .NET environment setup complete! ✓✓✓"
        echo ""
        info "Please run: source ~/.bashrc"
        info "Or open a new terminal to load environment variables"
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
    install_dotnet_sdk
    install_dotnet_tools
    install_aspire_cli
    setup_dev_certificates
    install_vscode_extensions
    
    echo ""
    verify_installation
    
    echo ""
    log "Installation log saved to: $LOG_FILE"
    
    echo ""
    info "Useful commands:"
    echo "  dotnet --info           # Show .NET information"
    echo "  dotnet workload list    # List installed workloads"
    echo "  dotnet tool list -g     # List global tools"
    echo "  aspire --help           # Aspire CLI help"
}

# Run main installation
main "$@"
