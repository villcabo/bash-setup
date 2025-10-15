#!/bin/bash

# ==============================================================
# MarckV Setup Manager
# ==============================================================
#
# Complete server configuration management tool
# Provides lifecycle management for both Docker aliases and Bash configurations:
# - Docker color aliases installation and management
# - Bash configuration setup (basic, full, codespace variants)
# - Version tracking and updates for both components
# - Status monitoring and clean uninstallation
#
# USAGE:
#   marckv-setup [command] [options]
#
# COMMANDS:
#   status                           - Show installation status for all configurations
#   install <docker|bash|docker-color> - Install specific component (type required for bash)
#   update                           - Update all installed configurations
#   uninstall                        - Remove all files and configurations
#   docker                           - Install/update docker aliases only
#   docker-color [version]           - Install/update docker-color-output binary
#   bash --type <type>               - Install/update bash config (type required)
#   version                          - Show manager version
#   help                             - Display help information
#
# BASH TYPES:
#   basic          - Basic bash configuration
#   full           - Full featured bash configuration
#   codespace      - GitHub Codespace optimized configuration
#   codespace_full - Full GitHub Codespace configuration
#
# EXAMPLES:
#   marckv-setup status                    - Check installation status
#   marckv-setup install docker           - Install docker aliases
#   marckv-setup install docker-color     - Install docker-color-output binary
#   marckv-setup install bash --type full - Install full bash config
#   marckv-setup bash --type basic        - Install basic bash config
#   marckv-setup docker                   - Install docker aliases
#   marckv-setup docker-color             - Install docker-color-output binary
#   marckv-setup docker-color 2.5.1       - Install specific version
#   marckv-setup update                   - Update all configurations
#
# FILES MANAGED:
#   ~/.docker_color_settings   - Docker aliases file
#   ~/.docker_color_version     - Docker version tracking
#   ~/.bashrc                   - Bash configuration file
#   ~/.bash_config_version      - Bash version tracking
#   ~/.bash_aliases            - Bash aliases configuration
#   ~/.zshrc                   - Zsh configuration (if exists)
#
# AUTHOR: villcabo
# REPOSITORY: https://github.com/villcabo/bash-setup
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
REPO_NAME="bash-setup"

# Docker configuration
LOCAL_FILE="$HOME/.docker_color_settings"
DOCKER_REMOTE_BASE_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/main/docker_configuration"
DOCKER_VERSION_FILE="$HOME/.docker_color_version"

# Bash configuration
BASH_CONFIG_FILE="$HOME/.bashrc"
BASH_REMOTE_BASE_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/main/bash_configuration"
BASH_VERSION_FILE="$HOME/.bash_config_version"

# Functions
confirm_operation() {
    local operation="$1"
    echo -ne "${YELLOW}Are you sure you want to $operation? ${GREEN}yes${NORMAL}/${RED}No${NORMAL}: "
    read -r response
    if [[ "${response,,}" != "yes" ]]; then
        echo -e "${RED}Operation cancelled${NORMAL}"
        return 1
    fi
    return 0
}

show_help() {
    echo -e "${BOLD}MarckV Setup Manager${NORMAL}"
    echo ""
    echo "Usage: $(basename "$0") [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo -e "  ${CYAN}status${NORMAL}                           Show installation status for all configurations"
    echo -e "  ${CYAN}install${NORMAL} <docker|bash|docker-color> Install specific component (type required for bash)"
    echo -e "  ${CYAN}update${NORMAL}                           Update all installed configurations"
    echo -e "  ${CYAN}uninstall${NORMAL}                        Remove all files and configurations"
    echo -e "  ${CYAN}docker${NORMAL}                           Install/update docker aliases only"
    echo -e "  ${CYAN}docker-color${NORMAL} [version]           Install/update docker-color-output binary"
    echo -e "  ${CYAN}bash${NORMAL} --type <type>               Install/update bash config (type required)"
    echo -e "  ${CYAN}version${NORMAL}                          Show manager version"
    echo -e "  ${CYAN}help${NORMAL}                             Show this help message"
    echo ""
    echo "Bash Types:"
    echo -e "  ${CYAN}basic${NORMAL}          Basic bash configuration"
    echo -e "  ${CYAN}full${NORMAL}           Full featured bash configuration"
    echo -e "  ${CYAN}codespace${NORMAL}      GitHub Codespace optimized configuration"
    echo -e "  ${CYAN}codespace_full${NORMAL} Full GitHub Codespace configuration"
    echo ""
    echo "Examples:"
    echo -e "  $(basename "$0") ${CYAN}status${NORMAL}                    Check installation status"
    echo -e "  $(basename "$0") ${CYAN}install docker${NORMAL}           Install docker aliases"
    echo -e "  $(basename "$0") ${CYAN}install docker-color${NORMAL}     Install docker-color-output binary"
    echo -e "  $(basename "$0") ${CYAN}install bash --type full${NORMAL} Install full bash config"
    echo -e "  $(basename "$0") ${CYAN}bash --type basic${NORMAL}        Install basic bash config"
    echo -e "  $(basename "$0") ${CYAN}docker${NORMAL}                   Install docker aliases"
    echo -e "  $(basename "$0") ${CYAN}docker-color${NORMAL}             Install docker-color-output binary"
    echo -e "  $(basename "$0") ${CYAN}docker-color 2.5.1${NORMAL}       Install specific version"
    echo -e "  $(basename "$0") ${CYAN}update${NORMAL}                   Update all configurations"
}

get_local_version() {
    if [[ -f "$DOCKER_VERSION_FILE" ]]; then
        cat "$DOCKER_VERSION_FILE"
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

get_bash_local_version() {
    if [[ -f "$BASH_VERSION_FILE" ]]; then
        cat "$BASH_VERSION_FILE"
    else
        cat << EOF
COMMIT_ID=not-installed
COMMIT_DATE=
COMMIT_MESSAGE=
COMMIT_BRANCH=
BASH_TYPE=
EOF
    fi
}

install_bash_config() {
    local bash_type="$1"

    if [[ -z "$bash_type" ]]; then
        echo -e "${RED}Error: Bash type is required${NORMAL}"
        echo -e "Available types: ${CYAN}basic${NORMAL}, ${CYAN}full${NORMAL}, ${CYAN}codespace${NORMAL}, ${CYAN}codespace_full${NORMAL}"
        return 1
    fi

    case "$bash_type" in
        basic|full|codespace|codespace_full)
            ;;
        *)
            echo -e "${RED}Error: Invalid bash type '${bash_type}'${NORMAL}"
            echo -e "Available types: ${CYAN}basic${NORMAL}, ${CYAN}full${NORMAL}, ${CYAN}codespace${NORMAL}, ${CYAN}codespace_full${NORMAL}"
            return 1
            ;;
    esac

    if ! confirm_operation "install bash configuration (${bash_type})"; then
        return 1
    fi

    echo -e "${BOLD}Installing Bash Configuration (${bash_type})...${NORMAL}"

    # Backup current bashrc if exists
    if [[ -f "$BASH_CONFIG_FILE" ]]; then
        cp "$BASH_CONFIG_FILE" "${BASH_CONFIG_FILE}.backup"
        echo -e "${BLUE}Backup created: ${BASH_CONFIG_FILE}.backup${NORMAL}"
    fi

    # Download the bash configuration file
    local download_url="${BASH_REMOTE_BASE_URL}/bash_${bash_type}.sh"
    if wget -q "$download_url" -O "$BASH_CONFIG_FILE"; then
        # Save version info including bash type
        {
            get_remote_version
            echo "BASH_TYPE=$bash_type"
        } > "$BASH_VERSION_FILE"

        echo -e "${GREEN}${BOLD}Bash configuration (${bash_type}) installed successfully${NORMAL}"
        echo -e "${BOLD}Run 'source ~/.bashrc' to apply changes${NORMAL}"
    else
        echo -e "${RED}${BOLD}Bash configuration installation failed${NORMAL}"
        # Restore backup if download failed
        if [[ -f "${BASH_CONFIG_FILE}.backup" ]]; then
            mv "${BASH_CONFIG_FILE}.backup" "$BASH_CONFIG_FILE"
            echo -e "${BLUE}Backup restored${NORMAL}"
        fi
        return 1
    fi
}

update_bash_config() {
    local bash_ver=$(get_bash_local_version)
    local bash_type=$(get_version_value "$bash_ver" "BASH_TYPE")

    if [[ -z "$bash_type" || "$bash_type" == "not-installed" ]]; then
        echo -e "${YELLOW}Bash configuration not installed. Use 'install bash --type <type>' first.${NORMAL}"
        return 1
    fi

    echo -e "${BOLD}Updating Bash Configuration (${bash_type})...${NORMAL}"
    install_bash_config "$bash_type"
}

install_docker_color() {
    local version="${1:-latest}"

    if ! confirm_operation "install Docker Color Output (${version})"; then
        return 1
    fi

    echo -e "${BOLD}Installing Docker Color Output (${version})...${NORMAL}"

    # Check if user has sudo privileges for system installation
    if [[ $EUID -eq 0 ]] || sudo -n true 2>/dev/null; then
        # Use the existing installer script with version parameter
        local installer_url="${DOCKER_REMOTE_BASE_URL}/../installer/docker-color_installers.sh"
        if [[ "$version" == "latest" ]]; then
            wget -q -O - "$installer_url" | sudo bash
        else
            wget -q -O - "$installer_url" | sudo bash -s -- -v "$version"
        fi

        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}${BOLD}Docker Color Output (${version}) installed successfully${NORMAL}"
        else
            echo -e "${RED}${BOLD}Docker Color Output installation failed${NORMAL}"
            return 1
        fi
    else
        echo -e "${RED}${BOLD}Error: Docker Color Output installation requires root privileges${NORMAL}"
        echo -e "${YELLOW}Please run with sudo or as root user${NORMAL}"
        return 1
    fi
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
    local bash_local_ver=$(get_bash_local_version)

    echo -e "${BOLD}MarckV Setup Status${NORMAL}"
    echo ""

    # Docker Aliases Status
    echo -e "${BOLD}=== Docker Aliases ===${NORMAL}"
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
    if [[ -f "$LOCAL_FILE" ]]; then
        echo -e "Aliases File: ${GREEN}Installed${NORMAL} (${LOCAL_FILE})"
    else
        echo -e "Aliases File: ${RED}Not found${NORMAL}"
    fi

    echo ""
    echo ""

    # Bash Configuration Status
    echo -e "${BOLD}=== Bash Configuration ===${NORMAL}"
    echo -e "${BOLD}Local Installation:${NORMAL}"
    local bash_local_hash=$(get_version_value "$bash_local_ver" "COMMIT_ID")
    local bash_type=$(get_version_value "$bash_local_ver" "BASH_TYPE")

    if [[ "$bash_local_hash" == "not-installed" ]]; then
        echo -e "  Status: ${RED}Not installed${NORMAL}"
    else
        local bash_local_date=$(get_version_value "$bash_local_ver" "COMMIT_DATE")
        local bash_local_message=$(get_version_value "$bash_local_ver" "COMMIT_MESSAGE")
        local bash_local_branch=$(get_version_value "$bash_local_ver" "COMMIT_BRANCH")

        echo -e "  Hash: ${CYAN}${bash_local_hash:0:12}...${NORMAL} (${bash_local_hash})"
        echo -e "  Date: ${CYAN}$bash_local_date${NORMAL}"
        echo -e "  Message: ${CYAN}$bash_local_message${NORMAL}"
        echo -e "  Branch: ${CYAN}$bash_local_branch${NORMAL}"
        echo -e "  Type: ${CYAN}$bash_type${NORMAL}"
    fi

    echo ""
    if [[ -f "$BASH_CONFIG_FILE" ]]; then
        echo -e "Bash Config File: ${GREEN}Installed${NORMAL} (${BASH_CONFIG_FILE})"
    else
        echo -e "Bash Config File: ${RED}Not found${NORMAL}"
    fi

    echo ""
    echo ""

    # Docker Color Output Status
    echo -e "${BOLD}=== Docker Color Output Binary ===${NORMAL}"
    if command -v docker-color-output >/dev/null 2>&1; then
        local docker_color_version=$(docker-color-output --version 2>/dev/null | head -1 || echo "Unknown version")
        local docker_color_path=$(which docker-color-output)
        echo -e "Status: ${GREEN}Installed${NORMAL}"
        echo -e "Version: ${CYAN}$docker_color_version${NORMAL}"
        echo -e "Location: ${CYAN}$docker_color_path${NORMAL}"
    else
        echo -e "Status: ${RED}Not installed${NORMAL}"
        echo -e "Note: Use '$(basename "$0") install docker-color' to install"
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
    local download_url="${DOCKER_REMOTE_BASE_URL}/docker-color_aliases_v2.sh"
    if wget -q "$download_url" -O "$LOCAL_FILE"; then
        # Save version info (commit hash, date, message, branch)
        get_remote_version > "$DOCKER_VERSION_FILE"
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
    local download_url="${DOCKER_REMOTE_BASE_URL}/docker-color_aliases_v2.sh"
    if wget -q "$download_url" -O "$LOCAL_FILE"; then
        # Save version info (commit hash, date, message, branch)
        get_remote_version > "$DOCKER_VERSION_FILE"
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
    if ! confirm_operation "uninstall all configurations"; then
        return 1
    fi

    echo -e "${BOLD}Uninstalling all configurations...${NORMAL}"

    # Remove Docker files
    [[ -f "$LOCAL_FILE" ]] && rm "$LOCAL_FILE" && echo -e "${GREEN}Removed $LOCAL_FILE${NORMAL}"
    [[ -f "$DOCKER_VERSION_FILE" ]] && rm "$DOCKER_VERSION_FILE" && echo -e "${GREEN}Removed $DOCKER_VERSION_FILE${NORMAL}"
    [[ -f "${LOCAL_FILE}.backup" ]] && rm "${LOCAL_FILE}.backup" && echo -e "${GREEN}Removed Docker backup file${NORMAL}"

    # Remove Bash files
    [[ -f "$BASH_VERSION_FILE" ]] && rm "$BASH_VERSION_FILE" && echo -e "${GREEN}Removed $BASH_VERSION_FILE${NORMAL}"
    [[ -f "${BASH_CONFIG_FILE}.backup" ]] && rm "${BASH_CONFIG_FILE}.backup" && echo -e "${GREEN}Removed Bash backup file${NORMAL}"

    # Remove from shell configs (user needs to do this manually for safety)
    echo -e "${YELLOW}Please manually remove the following line from ~/.bash_aliases:${NORMAL}"
    echo -e "   ${CYAN}[[ -s \"\$HOME/.docker_color_settings\" ]] && source \"\$HOME/.docker_color_settings\"${NORMAL}"

    echo -e "${GREEN}${BOLD}Uninstallation completed${NORMAL}"
}

update_all() {
    echo -e "${BOLD}Updating all installed configurations...${NORMAL}"
    echo ""

    local updated_any=false

    # Check and update Docker aliases if installed
    if [[ -f "$DOCKER_VERSION_FILE" ]]; then
        echo -e "${BOLD}Updating Docker aliases...${NORMAL}"
        update_aliases
        updated_any=true
    else
        echo -e "${YELLOW}Docker aliases not installed, skipping...${NORMAL}"
    fi

    echo ""

    # Check and update Bash configuration if installed
    if [[ -f "$BASH_VERSION_FILE" ]]; then
        echo -e "${BOLD}Updating Bash configuration...${NORMAL}"
        update_bash_config
        updated_any=true
    else
        echo -e "${YELLOW}Bash configuration not installed, skipping...${NORMAL}"
    fi

    if [[ "$updated_any" == true ]]; then
        echo ""
        echo -e "${GREEN}${BOLD}All updates completed${NORMAL}"
    else
        echo ""
        echo -e "${YELLOW}No configurations found to update${NORMAL}"
    fi
}

# Main script logic
case "${1:-status}" in
    status|st)
        show_status
        ;;
    install)
        case "$2" in
            docker)
                install_aliases
                ;;
            docker-color)
                install_docker_color "$3"
                ;;
            bash)
                if [[ "$3" == "--type" && -n "$4" ]]; then
                    install_bash_config "$4"
                else
                    echo -e "${RED}Error: Missing required parameter${NORMAL}"
                    echo -e "Usage: $(basename "$0") install bash --type <type>"
                    echo -e "Available types: ${CYAN}basic${NORMAL}, ${CYAN}full${NORMAL}, ${CYAN}codespace${NORMAL}, ${CYAN}codespace_full${NORMAL}"
                    exit 1
                fi
                ;;
            "")
                echo -e "${RED}Error: Missing required parameter${NORMAL}"
                echo -e "Usage: $(basename "$0") install <docker|bash|docker-color> [options]"
                echo -e "Examples:"
                echo -e "  $(basename "$0") install docker"
                echo -e "  $(basename "$0") install docker-color"
                echo -e "  $(basename "$0") install bash --type full"
                echo -e "  $(basename "$0") install bash --type codespace_full"
                exit 1
                ;;
            *)
                echo -e "${RED}Error: Invalid component '${2}'${NORMAL}"
                echo -e "Available components: ${CYAN}docker${NORMAL}, ${CYAN}bash${NORMAL}, ${CYAN}docker-color${NORMAL}"
                exit 1
                ;;
        esac
        ;;
    docker)
        install_aliases
        ;;
    docker-color)
        install_docker_color "$2"
        ;;
    bash)
        if [[ "$2" == "--type" && -n "$3" ]]; then
            install_bash_config "$3"
        else
            echo -e "${RED}Error: Missing required parameter${NORMAL}"
            echo -e "Usage: $(basename "$0") bash --type <type>"
            echo -e "Available types: ${CYAN}basic${NORMAL}, ${CYAN}full${NORMAL}, ${CYAN}codespace${NORMAL}, ${CYAN}codespace_full${NORMAL}"
            exit 1
        fi
        ;;
    update|up)
        update_all
        ;;
    uninstall|un)
        uninstall_aliases
        ;;
    version|ver|v)
        echo "MarckV Setup Manager v2.0"
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
