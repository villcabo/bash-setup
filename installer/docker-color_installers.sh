#!/bin/bash

# ==============================================================
# Docker Color Output Installer Script
# ==============================================================
#
# This script installs the Docker Color Output binary tool
#
# AUTHOR: villcabo
# REPOSITORY: https://github.com/villcabo/docker-color-output-install
#
# USAGE:
#   ./docker-color_installers.sh [options]
#
# OPTIONS:
#   -v, --version VERSION   Install specific version (default: latest)
#   -h, --help              Show help message
#
# EXAMPLES:
#   ./docker-color_installers.sh                 # Install latest version
#   ./docker-color_installers.sh -v 2.5.1        # Install version 2.5.1
#
# REQUIREMENTS:
#   - Root privileges (sudo)
#   - wget
#   - Internet connection
# ==============================================================

# Color codes for logging
NORMAL='\033[0m'
BOLD='\033[1m'
ITALIC='\033[3m'
QUIT_ITALIC='\033[23m'
UNDERLINE='\033[4m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo -e "${BOLD}Docker Color Output Installer${NORMAL}"
    echo ""
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo ""
    echo "Options:"
    echo -e "  ${CYAN}-v, --version VERSION${NORMAL}   Install specific version (default: latest)"
    echo -e "  ${CYAN}-h, --help${NORMAL}              Show this help message"
    echo ""
    echo "Examples:"
    echo -e "  $(basename "$0")                   Install latest version"
    echo -e "  $(basename "$0") ${CYAN}-v 2.5.1${NORMAL}         Install version 2.5.1"
    echo ""
    echo "Requirements:"
    echo -e "  ${YELLOW}• Root privileges (sudo)${NORMAL}"
    echo -e "  ${YELLOW}• wget command${NORMAL}"
    echo -e "  ${YELLOW}• Internet connection${NORMAL}"
}

# Default to latest version
VERSION="latest"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option '$1'${NORMAL}"
            echo ""
            usage
            exit 1
            ;;
    esac
done

# Validate root privileges
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}${BOLD}Error: This script requires root privileges${NORMAL}"
    echo -e "${YELLOW}Please run with sudo:${NORMAL} sudo $(basename "$0") $*"
    exit 1
fi

# Check for required commands
if ! command -v wget >/dev/null 2>&1; then
    echo -e "${RED}${BOLD}Error: wget is required but not installed${NORMAL}"
    echo -e "${YELLOW}Please install wget and try again${NORMAL}"
    exit 1
fi

# Start installation process
echo -e "${BOLD}Starting Docker Color Output installation...${NORMAL}"
echo ""

# Remove old versions
echo -e "${BOLD}Step 1: Removing existing installations...${NORMAL}"
rm -f /usr/bin/docker-color-output
rm -f /usr/local/bin/docker-color-output
echo -e "${GREEN}Existing installations removed successfully${NORMAL}"
echo ""

# Determine download URL based on version
if [[ "$VERSION" == "latest" ]]; then
    LATEST_URL="https://github.com/devemio/docker-color-output/releases/latest/download/docker-color-output-linux-amd64"
    echo -e "${BOLD}Step 2: Downloading ${CYAN}latest${NORMAL} version...${NORMAL}"
else
    LATEST_URL="https://github.com/devemio/docker-color-output/releases/download/${VERSION}/docker-color-output-linux-amd64"
    echo -e "${BOLD}Step 2: Downloading version ${CYAN}${VERSION}${NORMAL}...${NORMAL}"
fi
echo -e "${BLUE}Source: ${LATEST_URL}${NORMAL}"

# Download the specified version
if wget -q "$LATEST_URL" -O /usr/local/bin/docker-color-output; then
    echo -e "${GREEN}Download completed successfully${NORMAL}"
    echo ""

    # Set permissions
    echo -e "${BOLD}Step 3: Setting executable permissions...${NORMAL}"
    chmod 755 /usr/local/bin/docker-color-output
    echo -e "${GREEN}Permissions set successfully${NORMAL}"
    echo ""

    # Verify installation
    echo -e "${BOLD}Step 4: Verifying installation...${NORMAL}"
    if command -v docker-color-output >/dev/null 2>&1; then
        local version_info=$(docker-color-output --version 2>/dev/null | head -1 || echo "Version information not available")
        echo -e "${GREEN}${BOLD}Installation completed successfully!${NORMAL}"
        echo -e "${CYAN}Location: /usr/local/bin/docker-color-output${NORMAL}"
        echo -e "${CYAN}Version: ${version_info}${NORMAL}"
        echo ""
        echo -e "${YELLOW}You can now use 'docker-color-output' command or set it as Docker alias${NORMAL}"
    else
        echo -e "${RED}Installation verification failed${NORMAL}"
        exit 1
    fi
else
    echo -e "${RED}${BOLD}Failed to download Docker Color Output${NORMAL}"
    echo -e "${RED}Please check your internet connection and try again${NORMAL}"
    exit 1
fi
