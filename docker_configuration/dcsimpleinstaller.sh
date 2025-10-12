#!/bin/bash

# ==============================================================
# Docker Color Aliases Manager
# ==============================================================
#
# Management tool for docker-color_aliases_v2.sh configuration
# Provides complete lifecycle management for Docker aliases including:
# - Installation and configuration
# - Version tracking and updates
# - Status monitoring
# - Clean uninstallation
#
# USAGE:
#   dcsimpleinstaller [command]
#
# COMMANDS:
#   status      - Show current version and installation status
#   check       - Check for available updates
#   update      - Update to latest version with backup
#   install     - Install/reinstall aliases and shell configuration
#   uninstall   - Remove all files and configurations
#   version     - Show manager version
#   help        - Display help information
#
# EXAMPLES:
#   dcsimpleinstaller status    - Check current installation
#   dcsimpleinstaller update    - Update to latest version
#   dcsimpleinstaller install   - Fresh installation
#
# FILES MANAGED:
#   ~/.docker_color_settings   - Main aliases file
#   ~/.docker_color_version     - Version tracking
#   ~/.bash_aliases            - Bash configuration
#   ~/.zshrc                   - Zsh configuration (if exists)
#
# AUTHOR: villcabo
# REPOSITORY: https://github.com/villcabo/docker-color-output-install
# ==============================================================

# Color codes
NORMAL='\033[0m'
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'

# Configuration
REPO_OWNER="villcabo"
REPO_NAME="docker-color-output-install"
LOCAL_FILE="$HOME/.docker_color_settings"
REMOTE_BASE_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/main/docker_configuration"
VERSION_FILE="$HOME/.docker_color_version"

# Functions
show_help() {
    echo -e "${BOLD}Docker Color Aliases Manager${NORMAL}"
    echo ""
    echo "Usage: $(basename "$0") [COMMAND]"
    echo ""
    echo "Commands:"
    echo -e "  ${CYAN}status${NORMAL}     Show current version and status"
    echo -e "  ${CYAN}check${NORMAL}      Check for updates"
    echo -e "  ${CYAN}update${NORMAL}     Update to latest version"
    echo -e "  ${CYAN}install${NORMAL}    Install/reinstall aliases"
    echo -e "  ${CYAN}uninstall${NORMAL}  Remove aliases"
    echo -e "  ${CYAN}version${NORMAL}    Show version information"
    echo -e "  ${CYAN}help${NORMAL}       Show this help message"
}

get_local_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        cat "$VERSION_FILE"
    else
        echo "unknown"
    fi
}

get_remote_version() {
    curl -s "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/commits?path=docker_configuration/docker-color_aliases_v2.sh&per_page=1" | \
    grep -o '"sha":"[^"]*' | head -1 | cut -d'"' -f4 | cut -c1-7
}

show_status() {
    local local_ver=$(get_local_version)
    local remote_ver=$(get_remote_version)

    echo -e "${BOLD}Docker Color Aliases Status${NORMAL}"
    echo -e "Local version:  ${CYAN}$local_ver${NORMAL}"
    echo -e "Remote version: ${CYAN}$remote_ver${NORMAL}"

    if [[ -f "$LOCAL_FILE" ]]; then
        echo -e "Status: ${GREEN}Installed${NORMAL}"
        echo -e "File: $LOCAL_FILE"
    else
        echo -e "Status: ${RED}Not installed${NORMAL}"
    fi
}

check_updates() {
    local local_ver=$(get_local_version)
    local remote_ver=$(get_remote_version)

    if [[ "$local_ver" == "unknown" ]]; then
        echo -e "${YELLOW}Local version unknown. Run 'update' to get latest version.${NORMAL}"
        return 1
    elif [[ "$local_ver" != "$remote_ver" ]]; then
        echo -e "${YELLOW}Update available!${NORMAL}"
        echo -e "Current: ${CYAN}$local_ver${NORMAL}"
        echo -e "Latest:  ${CYAN}$remote_ver${NORMAL}"
        return 0
    else
        echo -e "${GREEN}You have the latest version!${NORMAL}"
        return 1
    fi
}

update_aliases() {
    echo -e "${BOLD}Updating Docker Color Aliases...${NORMAL}"

    # Backup current file if exists
    if [[ -f "$LOCAL_FILE" ]]; then
        cp "$LOCAL_FILE" "${LOCAL_FILE}.backup"
        echo -e "${BLUE}Backup created: ${LOCAL_FILE}.backup${NORMAL}"
    fi

    # Download latest version
    local download_url="${REMOTE_BASE_URL}/docker-color_aliases_v2.sh"
    if wget -q "$download_url" -O "$LOCAL_FILE"; then
        # Save version info
        get_remote_version > "$VERSION_FILE"
        echo -e "${GREEN}${BOLD}Update completed successfully${NORMAL}"
        echo -e "${BOLD}Run 'source ~/.bash_aliases' or 'source ~/.zshrc' to apply changes${NORMAL}"
    else
        echo -e "${RED}${BOLD}Update failed${NORMAL}"
        # Restore backup if download failed
        if [[ -f "${LOCAL_FILE}.backup" ]]; then
            mv "${LOCAL_FILE}.backup" "$LOCAL_FILE"
            echo -e "${BLUE}Backup restored${NORMAL}"
        fi
        exit 1
    fi
}

install_aliases() {
    echo -e "${BOLD}Installing Docker Color Aliases...${NORMAL}"

    # Download the aliases file directly
    local download_url="${REMOTE_BASE_URL}/docker-color_aliases_v2.sh"
    if wget -q "$download_url" -O "$LOCAL_FILE"; then
        # Save version info
        get_remote_version > "$VERSION_FILE"
        echo -e "${GREEN}${BOLD}Docker Color Aliases downloaded successfully${NORMAL}"

        # Configure shell files
        configure_shell_files

        echo -e "${GREEN}${BOLD}Installation completed successfully${NORMAL}"
        echo -e "${BOLD}Run 'source ~/.bash_aliases' or 'source ~/.zshrc' to apply changes${NORMAL}"
    else
        echo -e "${RED}${BOLD}Installation failed${NORMAL}"
        exit 1
    fi
}

configure_shell_files() {
    local bash_aliases="$HOME/.bash_aliases"
    local zshrc="$HOME/.zshrc"
    local source_line='[[ -s "$HOME/.docker_color_settings" ]] && source "$HOME/.docker_color_settings"'

    # Create .bash_aliases if it doesn't exist
    if [[ ! -f "$bash_aliases" ]]; then
        echo -e "${BOLD}Creating $bash_aliases...${NORMAL}"
        touch "$bash_aliases"
        echo -e "${GREEN}Created $bash_aliases${NORMAL}"
    fi

    # Add to .bash_aliases if not already there
    if ! grep -q "$source_line" "$bash_aliases"; then
        echo -e "${BOLD}Adding Docker Color settings to $bash_aliases...${NORMAL}"
        echo "$source_line" >> "$bash_aliases"
        echo -e "${GREEN}Added to $bash_aliases${NORMAL}"
    else
        echo -e "${YELLOW}Already configured in $bash_aliases${NORMAL}"
    fi

    # Add to .zshrc if it exists and not already there
    if [[ -f "$zshrc" ]]; then
        if ! grep -q "$source_line" "$zshrc"; then
            echo -e "${BOLD}Adding Docker Color settings to $zshrc...${NORMAL}"
            echo "$source_line" >> "$zshrc"
            echo -e "${GREEN}Added to $zshrc${NORMAL}"
        else
            echo -e "${YELLOW}Already configured in $zshrc${NORMAL}"
        fi
    fi
}

uninstall_aliases() {
    echo -e "${BOLD}Uninstalling Docker Color Aliases...${NORMAL}"

    # Remove files
    [[ -f "$LOCAL_FILE" ]] && rm "$LOCAL_FILE" && echo -e "${GREEN}Removed $LOCAL_FILE${NORMAL}"
    [[ -f "$VERSION_FILE" ]] && rm "$VERSION_FILE" && echo -e "${GREEN}Removed $VERSION_FILE${NORMAL}"
    [[ -f "${LOCAL_FILE}.backup" ]] && rm "${LOCAL_FILE}.backup" && echo -e "${GREEN}Removed backup file${NORMAL}"

    # Remove from shell configs (user needs to do this manually for safety)
    echo -e "${YELLOW}Please manually remove the following line from ~/.bash_aliases and ~/.zshrc:${NORMAL}"
    echo -e "   ${CYAN}[[ -s \"\$HOME/.docker_color_settings\" ]] && source \"\$HOME/.docker_color_settings\"${NORMAL}"

    echo -e "${GREEN}${BOLD}Uninstallation completed${NORMAL}"
}

# Main script logic
case "${1:-status}" in
    status|st)
        show_status
        ;;
    check|ch)
        check_updates
        ;;
    update|up)
        update_aliases
        ;;
    install|in)
        install_aliases
        ;;
    uninstall|un)
        uninstall_aliases
        ;;
    version|ver|v)
        echo "Docker Color Aliases Manager v1.0"
        ;;
    help|h|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NORMAL}"
        show_help
        exit 1
        ;;
esac
