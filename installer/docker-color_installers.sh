#!/bin/bash

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
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -v, --version VERSION   Specify the version to install (default: latest)"
    echo "  -h, --help              Display this help message"
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
            log "error" "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Start installation process
echo -e "${BOLD}➔ Starting Docker Color Output installation ⏳...${NORMAL}"

# Remove old versions
echo -e "${BOLD}➔ Removing existing installations ⏳...${NORMAL}"
rm -f /usr/bin/docker-color-output
rm -f /usr/local/bin/docker-color-output
echo -e "${GREEN}${BOLD}➔ Existing installations removed successfully${NORMAL}"

# Determine download URL based on version
if [[ "$VERSION" == "latest" ]]; then
    LATEST_URL="https://github.com/devemio/docker-color-output/releases/latest/download/docker-color-output-linux-amd64"
    echo -e "${BOLD}➔ Downloading ${ITALIC}latest${QUIT_ITALIC} version ⏳...${NORMAL}"
else
    LATEST_URL="https://github.com/devemio/docker-color-output/releases/download/${VERSION}/docker-color-output-linux-amd64"
    echo -e "${BOLD}➔ Downloading ${ITALIC}${VERSION}${QUIT_ITALIC} version ⏳...${NORMAL}"
fi

# Download the specified version
if wget -q "$LATEST_URL" -O /usr/local/bin/docker-color-output; then
    # Set permissions
    chmod 755 /usr/local/bin/docker-color-output
    
    echo -e "${GREEN}${BOLD}➔ Docker Color Output installed successfully in ${ITALIC}/usr/local/bin 🚀${NORMAL}"

    /usr/local/bin/docker-color-output
else
    echo -e "${BOLD}➔ Failed to download Docker Color Output ❌${NORMAL}"
    exit 1
fi
