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
confirm_operation() {
    local operation="$1"
    echo -e "${YELLOW}Are you sure you want to $operation? (type 'yes' to confirm): ${NORMAL}"
    read -r response
    if [[ "$response" != "yes" ]]; then
        echo -e "${RED}Operation cancelled${NORMAL}"
        return 1
    fi
    return 0
}

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
        cat << EOF
COMMIT_ID=not-installed
COMMIT_DATE=
COMMIT_MESSAGE=
COMMIT_BRANCH=
EOF
    fi
}

get_version_value() {
    local version_content="$1"
    local key="$2"
    echo "$version_content" | grep "^$key=" | cut -d'=' -f2-
}

get_remote_version() {
    # Get latest commit info from main branch
    local api_url="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/commits/main"
    local commit_info=$(curl -s --connect-timeout 10 "$api_url" 2>/dev/null)

    if [[ -n "$commit_info" && "$commit_info" != *"API rate limit"* ]]; then
        local hash=$(echo "$commit_info" | grep '"sha"' | head -1 | cut -d'"' -f4)
        local date=$(echo "$commit_info" | grep '"date"' | head -1 | cut -d'"' -f4)
        local message=$(echo "$commit_info" | grep '"message"' | head -1 | cut -d'"' -f4 | head -c 80)
        local branch="main"

        if [[ -n "$hash" ]]; then
            cat << EOF
COMMIT_ID=$hash
COMMIT_DATE=$date
COMMIT_MESSAGE=$message
COMMIT_BRANCH=$branch
EOF
        else
            cat << EOF
COMMIT_ID=unknown
COMMIT_DATE=$(date -Iseconds)
COMMIT_MESSAGE=Local installation
COMMIT_BRANCH=main
EOF
        fi
    else
        cat << EOF
COMMIT_ID=unknown
COMMIT_DATE=$(date -Iseconds)
COMMIT_MESSAGE=Local installation
COMMIT_BRANCH=main
EOF
    fi
}

show_status() {
    local local_ver=$(get_local_version)
    local remote_ver=$(get_remote_version)

    echo -e "${BOLD}Docker Color Aliases Status${NORMAL}"
    echo ""

    # Parse and display local version info
    echo -e "${BOLD}Local Installation:${NORMAL}"
    local local_hash=$(get_version_value "$local_ver" "COMMIT_ID")

    if [[ "$local_hash" == "not-installed" ]]; then
        echo -e "  Status: ${RED}Not installed${NORMAL}"
    else
        local local_date=$(get_version_value "$local_ver" "COMMIT_DATE")
        local local_message=$(get_version_value "$local_ver" "COMMIT_MESSAGE")
        local local_branch=$(get_version_value "$local_ver" "COMMIT_BRANCH")

        echo -e "  Hash: ${CYAN}${local_hash:0:12}...${NORMAL} (${local_hash})"
        echo -e "  Date: ${CYAN}$local_date${NORMAL}"
        echo -e "  Message: ${CYAN}$local_message${NORMAL}"
        echo -e "  Branch: ${CYAN}$local_branch${NORMAL}"
    fi

    echo ""

    # Parse and display remote version info
    echo -e "${BOLD}Remote Repository (Latest):${NORMAL}"
    local remote_hash=$(get_version_value "$remote_ver" "COMMIT_ID")
    local remote_date=$(get_version_value "$remote_ver" "COMMIT_DATE")
    local remote_message=$(get_version_value "$remote_ver" "COMMIT_MESSAGE")
    local remote_branch=$(get_version_value "$remote_ver" "COMMIT_BRANCH")

    echo -e "  Hash: ${CYAN}${remote_hash:0:12}...${NORMAL} (${remote_hash})"
    echo -e "  Date: ${CYAN}$remote_date${NORMAL}"
    echo -e "  Message: ${CYAN}$remote_message${NORMAL}"
    echo -e "  Branch: ${CYAN}$remote_branch${NORMAL}"

    echo ""

    # Installation status
    if [[ -f "$LOCAL_FILE" ]]; then
        echo -e "Aliases File: ${GREEN}Installed${NORMAL} (${LOCAL_FILE})"
    else
        echo -e "Aliases File: ${RED}Not found${NORMAL}"
    fi
}

check_updates() {
    local local_ver=$(get_local_version)
    local remote_ver=$(get_remote_version)

    local local_hash=$(get_version_value "$local_ver" "COMMIT_ID")
    local remote_hash=$(get_version_value "$remote_ver" "COMMIT_ID")

    if [[ "$local_hash" == "not-installed" || "$local_hash" == "unknown" ]]; then
        echo -e "${YELLOW}Local version unknown. Run 'install' to get latest version.${NORMAL}"
        return 1
    elif [[ "$local_hash" != "$remote_hash" ]]; then
        echo -e "${YELLOW}Update available!${NORMAL}"
        echo -e "Local:  ${CYAN}${local_hash:0:12}...${NORMAL}"
        echo -e "Remote: ${CYAN}${remote_hash:0:12}...${NORMAL}"
        return 1
    else
        echo -e "${GREEN}You have the latest version!${NORMAL}"
        echo -e "Hash: ${CYAN}${local_hash:0:12}...${NORMAL}"
        return 0
    fi
}

update_aliases() {
    if ! confirm_operation "update Docker Color Aliases"; then
        return 1
    fi

    echo -e "${BOLD}Updating Docker Color Aliases...${NORMAL}"

    # Backup current file if exists
    if [[ -f "$LOCAL_FILE" ]]; then
        cp "$LOCAL_FILE" "${LOCAL_FILE}.backup"
        echo -e "${BLUE}Backup created: ${LOCAL_FILE}.backup${NORMAL}"
    fi

    # Download latest version
    local download_url="${REMOTE_BASE_URL}/docker-color_aliases_v2.sh"
    if wget -q "$download_url" -O "$LOCAL_FILE"; then
        # Save version info (commit hash, date, message, branch)
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
    if ! confirm_operation "install Docker Color Aliases"; then
        return 1
    fi

    echo -e "${BOLD}Installing Docker Color Aliases...${NORMAL}"

    # Download the aliases file directly
    local download_url="${REMOTE_BASE_URL}/docker-color_aliases_v2.sh"
    if wget -q "$download_url" -O "$LOCAL_FILE"; then
        # Save version info (commit hash, date, message, branch)
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
    local bashrc="$HOME/.bashrc"
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

    # Check if .bashrc sources .bash_aliases
    local bashrc_needs_config=true
    if [[ -f "$bashrc" ]]; then
        if grep -q "\.bash_aliases" "$bashrc" || grep -q "bash_aliases" "$bashrc"; then
            bashrc_needs_config=false
        fi
    fi

    # Check if .zshrc sources .bash_aliases
    local zshrc_needs_config=true
    if [[ -f "$zshrc" ]]; then
        if grep -q "\.bash_aliases" "$zshrc" || grep -q "bash_aliases" "$zshrc"; then
            zshrc_needs_config=false
        fi
    fi

    # Show instructions if needed
    if [[ "$bashrc_needs_config" == true && -f "$bashrc" ]]; then
        echo ""
        echo -e "${YELLOW}${BOLD}IMPORTANT: Your .bashrc doesn't source .bash_aliases${NORMAL}"
        echo -e "${BOLD}To enable Docker Color Aliases in bash, add this line to your ~/.bashrc:${NORMAL}"
        echo -e "${CYAN}if [ -f ~/.bash_aliases ]; then . ~/.bash_aliases; fi${NORMAL}"
        echo ""
    fi

    if [[ "$zshrc_needs_config" == true && -f "$zshrc" ]]; then
        echo -e "${YELLOW}${BOLD}IMPORTANT: Your .zshrc doesn't source .bash_aliases${NORMAL}"
        echo -e "${BOLD}To enable Docker Color Aliases in zsh, add this line to your ~/.zshrc:${NORMAL}"
        echo -e "${CYAN}[[ -f ~/.bash_aliases ]] && source ~/.bash_aliases${NORMAL}"
        echo ""
    fi
}

uninstall_aliases() {
    if ! confirm_operation "uninstall Docker Color Aliases"; then
        return 1
    fi

    echo -e "${BOLD}Uninstalling Docker Color Aliases...${NORMAL}"

    # Remove files
    [[ -f "$LOCAL_FILE" ]] && rm "$LOCAL_FILE" && echo -e "${GREEN}Removed $LOCAL_FILE${NORMAL}"
    [[ -f "$VERSION_FILE" ]] && rm "$VERSION_FILE" && echo -e "${GREEN}Removed $VERSION_FILE${NORMAL}"
    [[ -f "${LOCAL_FILE}.backup" ]] && rm "${LOCAL_FILE}.backup" && echo -e "${GREEN}Removed backup file${NORMAL}"

    # Remove from shell configs (user needs to do this manually for safety)
    echo -e "${YELLOW}Please manually remove the following line from ~/.bash_aliases:${NORMAL}"
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
