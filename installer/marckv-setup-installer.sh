#!/bin/bash

# MarckV Setup Manager Installer
# This script installs the marckv-setup management tool

# Author: villcabo
# Repository: https://github.com/villcabo/bash-setup

# Color codes for logging
NORMAL='\033[0m'
BOLD='\033[1m'
ITALIC='\033[3m'
QUIT_ITALIC='\033[23m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'

# GitHub repository details
REPO_OWNER="villcabo"
REPO_NAME="bash-setup"
GITHUB_RAW_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/main/installer"

# Determine binary directory based on user permissions
if [[ $EUID -eq 0 ]]; then
    BIN_DIR="/usr/local/bin"
else
    BIN_DIR="$HOME/.local/bin"
    # Create local bin directory if it doesn't exist
    mkdir -p "$BIN_DIR"
fi

MANAGER_SCRIPT="$BIN_DIR/marckv-setup"

# Function to display usage
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help       Display this help message"
    echo ""
    echo "This installer will download and install the marckv-setup management tool."
    echo "Use 'marckv-setup help' after installation for available commands."
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}${BOLD}Unknown option: $1${NORMAL}"
            usage
            exit 1
            ;;
    esac
    shift
done

# Start installation process
echo -e "${BOLD}Starting MarckV Setup Manager installation...${NORMAL}"
echo ""

# Download and install the management script
echo -e "${BOLD}Step 1: Downloading marckv-setup...${NORMAL}"
echo -e "${BLUE}Source: ${GITHUB_RAW_URL}/marckv-setup.sh${NORMAL}"
if wget -q "${GITHUB_RAW_URL}/marckv-setup.sh" -O "$MANAGER_SCRIPT"; then
    echo -e "${GREEN}Download completed successfully${NORMAL}"
    echo ""

    echo -e "${BOLD}Step 2: Setting executable permissions...${NORMAL}"
    chmod +x "$MANAGER_SCRIPT"
    echo -e "${GREEN}Permissions set successfully${NORMAL}"
    echo ""
else
    echo -e "${RED}${BOLD}Failed to download marckv-setup${NORMAL}"
    echo -e "${RED}Please check your internet connection and try again${NORMAL}"
    exit 1
fi

# Add to PATH if not already there (for non-root users)
if [[ "$BIN_DIR" == "$HOME/.local/bin" ]]; then
    echo -e "${BOLD}Step 3: Configuring PATH environment...${NORMAL}"
    shell_profile=""
    if [[ -f "$HOME/.bashrc" ]]; then
        shell_profile="$HOME/.bashrc"
    elif [[ -f "$HOME/.zshrc" ]]; then
        shell_profile="$HOME/.zshrc"
    fi

    if [[ -n "$shell_profile" ]]; then
        if ! grep -q "\$HOME/.local/bin" "$shell_profile"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$shell_profile"
            echo -e "${GREEN}Added $BIN_DIR to PATH in $shell_profile${NORMAL}"
            echo -e "${YELLOW}Please run: ${CYAN}source $shell_profile${NORMAL} ${YELLOW}or restart your terminal${NORMAL}"
        else
            echo -e "${GREEN}PATH already configured in $shell_profile${NORMAL}"
        fi
    fi
    echo ""
fi

echo -e "${BOLD}Step 4: Verifying installation...${NORMAL}"
if [[ -x "$MANAGER_SCRIPT" ]]; then
    echo -e "${GREEN}Installation verification successful${NORMAL}"
    echo -e "${CYAN}Location: $MANAGER_SCRIPT${NORMAL}"
    echo ""

    echo -e "${GREEN}${BOLD}Installation completed successfully!${NORMAL}"
    echo -e "${BOLD}Management tool installed at: ${CYAN}$MANAGER_SCRIPT${NORMAL}"
    echo -e "${BOLD}Usage: ${CYAN}marckv-setup [command]${NORMAL}"
    echo ""
    echo -e "${YELLOW}${BOLD}Available commands:${NORMAL}"
    echo -e "${CYAN}marckv-setup help${NORMAL}                          - Show help"
    echo -e "${CYAN}marckv-setup install docker${NORMAL}                - Install docker aliases"
    echo -e "${CYAN}marckv-setup install bash --type full${NORMAL}      - Install full bash config"
    echo -e "${CYAN}marckv-setup install bash --type codespace_full${NORMAL} - Install codespace bash config"
else
    echo -e "${RED}Installation verification failed${NORMAL}"
    exit 1
fi
