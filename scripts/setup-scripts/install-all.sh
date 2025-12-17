#!/bin/bash
# ============================================================================
# MASTER DEVELOPMENT ENVIRONMENT INSTALLER
# ============================================================================
# This script orchestrates installation of all development environments
# Run individual scripts or install everything at once

set -e

SCRIPT_DIR="$HOME/setup-scripts"
LOG_DIR="$SCRIPT_DIR/logs"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Create log directory
mkdir -p "$LOG_DIR"

banner() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${GREEN}Development Environment Installer${NC}                     ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_menu() {
    echo -e "${YELLOW}Available Installations:${NC}"
    echo ""
    echo "  1) Android Development Environment"
    echo "     - Java JDK 21"
    echo "     - Android SDK & Command Line Tools"
    echo "     - Android NDK"
    echo "     - Platform Tools (ADB)"
    echo "     - Gradle"
    echo ""
    echo "  2) .NET Development Environment"
    echo "     - .NET SDK 10.0"
    echo "     - Entity Framework Core Tools"
    echo "     - Aspire Workload & CLI"
    echo "     - Development Certificates"
    echo ""
    echo "  3) React/Node.js Development Environment"
    echo "     - NVM (Node Version Manager)"
    echo "     - Node.js LTS"
    echo "     - Yarn & pnpm"
    echo "     - React Tools (Vite, Create React App)"
    echo "     - Global npm packages"
    echo ""
    echo "  4) Install Everything"
    echo "     - All of the above environments"
    echo ""
    echo "  5) Check Installation Status"
    echo "     - Verify what's already installed"
    echo ""
    echo "  6) View Installation Logs"
    echo "     - Browse previous installation logs"
    echo ""
    echo "  q) Quit"
    echo ""
}

check_status() {
    echo -e "${BLUE}Checking installation status...${NC}"
    echo ""
    
    # Android
    echo -e "${YELLOW}Android Development:${NC}"
    if command -v java >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Java: $(java -version 2>&1 | head -n 1)"
    else
        echo -e "  ${RED}✗${NC} Java not installed"
    fi
    
    if [[ -d "$HOME/Android/Sdk" ]]; then
        echo -e "  ${GREEN}✓${NC} Android SDK: $HOME/Android/Sdk"
    else
        echo -e "  ${RED}✗${NC} Android SDK not installed"
    fi
    
    if command -v adb >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} ADB: $(adb version | head -n 1)"
    else
        echo -e "  ${RED}✗${NC} ADB not available"
    fi
    
    echo ""
    
    # .NET
    echo -e "${YELLOW}.NET Development:${NC}"
    if command -v dotnet >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} .NET SDK: $(dotnet --version)"
        
        if dotnet workload list 2>/dev/null | grep -q "aspire"; then
            echo -e "  ${GREEN}✓${NC} Aspire workload installed"
        else
            echo -e "  ${RED}✗${NC} Aspire workload not installed"
        fi
    else
        echo -e "  ${RED}✗${NC} .NET SDK not installed"
    fi
    
    echo ""
    
    # Node.js
    echo -e "${YELLOW}React/Node.js Development:${NC}"
    if [[ -d "$HOME/.nvm" ]]; then
        echo -e "  ${GREEN}✓${NC} NVM installed"
    else
        echo -e "  ${RED}✗${NC} NVM not installed"
    fi
    
    if command -v node >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Node.js: $(node --version)"
        echo -e "  ${GREEN}✓${NC} npm: $(npm --version)"
    else
        echo -e "  ${RED}✗${NC} Node.js not installed"
    fi
    
    if command -v yarn >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Yarn: $(yarn --version)"
    else
        echo -e "  ${RED}✗${NC} Yarn not installed"
    fi
    
    echo ""
}

view_logs() {
    echo -e "${BLUE}Installation Logs:${NC}"
    echo ""
    
    if [[ ! -d "$LOG_DIR" ]] || [[ -z "$(ls -A $LOG_DIR)" ]]; then
        echo "No installation logs found."
        return
    fi
    
    ls -lht "$LOG_DIR" | tail -n +2 | head -n 10
    echo ""
    read -p "Enter log filename to view (or press Enter to skip): " logfile
    
    if [[ -n "$logfile" ]] && [[ -f "$LOG_DIR/$logfile" ]]; then
        less "$LOG_DIR/$logfile"
    fi
}

run_installer() {
    local script="$1"
    local name="$2"
    
    if [[ ! -f "$script" ]]; then
        echo -e "${RED}Error: $script not found${NC}"
        return 1
    fi
    
    chmod +x "$script"
    echo ""
    echo -e "${GREEN}Running $name installer...${NC}"
    echo ""
    
    bash "$script"
    
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        echo ""
        echo -e "${GREEN}✓ $name installation completed${NC}"
    else
        echo ""
        echo -e "${RED}✗ $name installation failed (exit code: $exit_code)${NC}"
    fi
    
    return $exit_code
}

install_all() {
    echo -e "${BLUE}Installing all development environments...${NC}"
    echo ""
    
    local failed=0
    
    run_installer "$SCRIPT_DIR/install-android.sh" "Android" || ((failed++))
    echo ""
    
    run_installer "$SCRIPT_DIR/install-dotnet.sh" ".NET" || ((failed++))
    echo ""
    
    run_installer "$SCRIPT_DIR/install-react.sh" "React/Node.js" || ((failed++))
    echo ""
    
    if [[ $failed -eq 0 ]]; then
        echo -e "${GREEN}✓✓✓ All installations completed successfully! ✓✓✓${NC}"
    else
        echo -e "${YELLOW}⚠ $failed installation(s) failed. Check logs for details.${NC}"
    fi
}

main() {
    banner
    
    while true; do
        show_menu
        read -p "Select an option: " choice
        
        case $choice in
            1)
                run_installer "$SCRIPT_DIR/install-android.sh" "Android"
                read -p "Press Enter to continue..."
                ;;
            2)
                run_installer "$SCRIPT_DIR/install-dotnet.sh" ".NET"
                read -p "Press Enter to continue..."
                ;;
            3)
                run_installer "$SCRIPT_DIR/install-react.sh" "React/Node.js"
                read -p "Press Enter to continue..."
                ;;
            4)
                install_all
                read -p "Press Enter to continue..."
                ;;
            5)
                check_status
                read -p "Press Enter to continue..."
                ;;
            6)
                view_logs
                ;;
            q|Q)
                echo ""
                echo "Exiting installer. Happy coding!"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                sleep 1
                ;;
        esac
        
        clear
        banner
    done
}

# Check if running in interactive mode
if [[ -t 0 ]]; then
    main
else
    echo "This script should be run interactively"
    exit 1
fi

