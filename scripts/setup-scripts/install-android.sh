#!/bin/bash
# ============================================================================
# ANDROID DEVELOPMENT ENVIRONMENT SETUP
# ============================================================================
# This script installs all necessary tools for Android development
# Safe to run multiple times (idempotent)

set -e  # Exit on error

SCRIPT_NAME="Android Setup"
LOG_FILE="$HOME/setup-scripts/logs/android-install-$(date +%Y%m%d-%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create log directory
mkdir -p "$HOME/setup-scripts/logs"

# Logging function
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

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ============================================================================
# JAVA INSTALLATION
# ============================================================================

install_java() {
    log "Installing Java Development Kit..."
    
    if command_exists java; then
        info "Java already installed: $(java -version 2>&1 | head -n 1)"
        return 0
    fi
    
    sudo apt update
    sudo apt install -y openjdk-21-jdk openjdk-21-jre
    
    log "✓ Java installed successfully"
}

# ============================================================================
# ANDROID SDK INSTALLATION
# ============================================================================

install_android_sdk() {
    log "Installing Android SDK..."
    
    local sdk_dir="$HOME/Android/Sdk"
    local cmdline_tools_dir="$sdk_dir/cmdline-tools"
    
    if [[ -d "$sdk_dir" ]]; then
        info "Android SDK directory already exists at $sdk_dir"
    else
        mkdir -p "$sdk_dir"
        log "Created Android SDK directory at $sdk_dir"
    fi
    
    # Download command line tools if not present
    if [[ ! -d "$cmdline_tools_dir/latest" ]]; then
        log "Downloading Android Command Line Tools..."
        
        local tools_url="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
        local temp_zip="/tmp/cmdline-tools.zip"
        
        wget -q --show-progress "$tools_url" -O "$temp_zip"
        
        mkdir -p "$cmdline_tools_dir/latest"
        unzip -q "$temp_zip" -d "$cmdline_tools_dir"
        mv "$cmdline_tools_dir/cmdline-tools"/* "$cmdline_tools_dir/latest/"
        rmdir "$cmdline_tools_dir/cmdline-tools"
        rm "$temp_zip"
        
        log "✓ Command Line Tools installed"
    else
        info "Command Line Tools already installed"
    fi
}

# ============================================================================
# ANDROID SDK COMPONENTS
# ============================================================================

install_sdk_components() {
    log "Installing Android SDK components..."
    
    local sdk_manager="$HOME/Android/Sdk/cmdline-tools/latest/bin/sdkmanager"
    
    if [[ ! -f "$sdk_manager" ]]; then
        error "sdkmanager not found. Please run install_android_sdk first."
        return 1
    fi
    
    # Accept licenses
    yes | "$sdk_manager" --licenses >/dev/null 2>&1 || true
    
    log "Installing platform tools, build tools, and platforms..."
    
    # Install essential components
    "$sdk_manager" \
        "platform-tools" \
        "platforms;android-34" \
        "build-tools;34.0.0" \
        "emulator" \
        "system-images;android-34;google_apis;x86_64" \
        2>&1 | tee -a "$LOG_FILE"
    
    log "✓ SDK components installed"
}

# ============================================================================
# ANDROID NDK INSTALLATION
# ============================================================================

install_ndk() {
    log "Installing Android NDK..."
    
    local sdk_manager="$HOME/Android/Sdk/cmdline-tools/latest/bin/sdkmanager"
    local ndk_version="27.1.12297006"
    local ndk_dir="$HOME/Android/Sdk/ndk/$ndk_version"
    
    if [[ -d "$ndk_dir" ]]; then
        info "NDK already installed at $ndk_dir"
        return 0
    fi
    
    "$sdk_manager" "ndk;$ndk_version" 2>&1 | tee -a "$LOG_FILE"
    
    log "✓ NDK installed"
}

# ============================================================================
# GRADLE INSTALLATION (Optional)
# ============================================================================

install_gradle() {
    log "Installing Gradle..."
    
    if command_exists gradle; then
        info "Gradle already installed: $(gradle --version | head -n 1)"
        return 0
    fi
    
    sudo apt install -y gradle
    
    log "✓ Gradle installed"
}

# ============================================================================
# ANDROID STUDIO (Optional)
# ============================================================================

install_android_studio() {
    read -p "Do you want to install Android Studio? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Skipping Android Studio installation"
        return 0
    fi
    
    log "Installing Android Studio..."
    
    if command_exists android-studio; then
        info "Android Studio already installed"
        return 0
    fi
    
    # Install via snap (easiest method)
    sudo snap install android-studio --classic
    
    log "✓ Android Studio installed"
}

# ============================================================================
# DEPENDENCIES
# ============================================================================

install_dependencies() {
    log "Installing system dependencies..."
    
    sudo apt update
    sudo apt install -y \
        wget \
        unzip \
        git \
        curl \
        libc6:i386 \
        libncurses5:i386 \
        libstdc++6:i386 \
        lib32z1 \
        libbz2-1.0:i386
    
    log "✓ Dependencies installed"
}

# ============================================================================
# ENVIRONMENT VERIFICATION
# ============================================================================

verify_installation() {
    log "Verifying installation..."
    
    local all_ok=true
    
    # Check Java
    if command_exists java; then
        log "✓ Java: $(java -version 2>&1 | head -n 1)"
    else
        error "✗ Java not found"
        all_ok=false
    fi
    
    # Check Android SDK
    if [[ -d "$HOME/Android/Sdk" ]]; then
        log "✓ Android SDK: $HOME/Android/Sdk"
    else
        error "✗ Android SDK not found"
        all_ok=false
    fi
    
    # Check adb
    if command_exists adb; then
        log "✓ ADB: $(adb version | head -n 1)"
    else
        warn "✗ ADB not in PATH (may need to reload shell)"
    fi
    
    if [[ "$all_ok" == true ]]; then
        log "✓✓✓ Android environment setup complete! ✓✓✓"
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
    install_java
    install_android_sdk
    install_sdk_components
    install_ndk
    install_gradle
    install_android_studio
    
    echo ""
    verify_installation
    
    echo ""
    log "Installation log saved to: $LOG_FILE"
}

# Run main installation
main "$@"

