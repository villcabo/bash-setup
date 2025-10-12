#!/bin/bash

# Docker Color Aliases Manager Installer
# This script installs the dcsimpleinstaller management tool

# Author: villcabo
# Repository: https://github.com/villcabo/docker-color-output-install

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
REPO_NAME="docker-color-output-install"
GITHUB_RAW_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/main/docker_configuration"

# Determine binary directory based on user permissions
if [[ $EUID -eq 0 ]]; then
    BIN_DIR="/usr/local/bin"
else
    BIN_DIR="$HOME/.local/bin"
    # Create local bin directory if it doesn't exist
    mkdir -p "$BIN_DIR"
fi

MANAGER_SCRIPT="$BIN_DIR/dcsimpleinstaller"

# Function to display usage
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help       Display this help message"
    echo ""
    echo "This installer will download and install the dcsimpleinstaller management tool."
    echo "Use 'dcsimpleinstaller help' after installation for available commands."
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
echo -e "${BOLD}Installing Docker Color Aliases Manager...${NORMAL}"

# Download and install the management script
echo -e "${BOLD}Downloading dcsimpleinstaller...${NORMAL}"
if wget -q "${GITHUB_RAW_URL}/dcsimpleinstaller.sh" -O "$MANAGER_SCRIPT"; then
    chmod +x "$MANAGER_SCRIPT"
    echo -e "${GREEN}${BOLD}dcsimpleinstaller downloaded and installed successfully${NORMAL}"
else
    echo -e "${RED}${BOLD}Failed to download dcsimpleinstaller${NORMAL}"
    exit 1
fi

# Add to PATH if not already there (for non-root users)
if [[ "$BIN_DIR" == "$HOME/.local/bin" ]]; then
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
        fi
    fi
fi

echo -e "${GREEN}${BOLD}Installation completed successfully${NORMAL}"
echo -e "${BOLD}Management tool installed at: ${CYAN}$MANAGER_SCRIPT${NORMAL}"
echo -e "${BOLD}Usage: ${CYAN}dcsimpleinstaller [command]${NORMAL}"
echo -e "${BOLD}Get started: ${CYAN}dcsimpleinstaller help${NORMAL}"
echo -e "${BOLD}Install aliases: ${CYAN}dcsimpleinstaller install${NORMAL}"
