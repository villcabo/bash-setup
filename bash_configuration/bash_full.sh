#!/bin/bash
# ==============================================================
# Enhanced Bash Configuration (bash_full.sh)
# ==============================================================
#
# AUTHOR: villcabo
# REPOSITORY: https://github.com/villcabo/docker-color-output-install
# VERSION: 1.0
# CREATED: October 2025
#
# DESCRIPTION:
# Complete bash configuration file with enhanced features including:
# - Colorized prompt based on user privileges (root/normal user)
# - Smart directory colors and ls aliases
# - Git integration with branch display and status
# - Advanced command history management
# - Docker and development-focused aliases
# - Performance optimizations for bash shell
# - Cross-platform compatibility enhancements
#
# FEATURES:
# - Root user: Red prompt for security awareness
# - Normal user: Green prompt for standard operations
# - Git branch display in prompt when in git repositories
# - Enhanced history with timestamps and deduplication
# - Color-coded file listings with dircolors
# - Development-friendly aliases and functions
# - Docker integration support
#
# USAGE:
# This file can be used as a complete replacement for ~/.bashrc
# or sourced from your existing bashrc for additional functionality.
# Run 'bashrc_help' or 'bhelp' after installation to see all features.
#
# INSTALLATION:
# Download the latest version from GitHub repository:
# wget https://raw.githubusercontent.com/villcabo/docker-color-output-install/main/bash_configuration/bash_full.sh -O ~/.bashrc
# source ~/.bashrc
#
# COMPATIBILITY:
# - Bash 4.0+
# - Linux distributions (Ubuntu, Debian, CentOS, etc.)
# - macOS with bash installed
# - Windows WSL/WSL2
#
# ==============================================================

# ~/.bashrc: executed by bash(1) for non-login shells.

# Note: PS1 and umask are already set in /etc/profile. You should not
# need this unless you want different defaults for root.

# Color configuration for prompt according to user (root/non-root)
if [ $(id -u) -eq 0 ]; then
  # Root user - prompt in red
  PS1='\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
  # Normal user - prompt in green
  PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
fi

# --------------------------------------------------------------------------

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"

	# Common aliases
	alias ls='ls --color=auto'
	alias ll='ls --color=auto -alF'
	alias la='ls --color=auto -A'
	alias l='ls --color=auto -lA'
	alias grep='grep --color=auto'
	alias fgrep='fgrep --color=auto'
	alias egrep='egrep --color=auto'
	alias fgrepn='fgrep --color=never'
	alias egrepn='egrep --color=never'
fi


# Add bin directories to PATH if they exist
if [ -d "$HOME/.local/bin" ]; then
  PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "$HOME/bin" ]; then
  PATH="$HOME/bin:$PATH"
fi

# Load custom aliases if the file exists
if [ -f $HOME/.bash_aliases ]; then
  . $HOME/.bash_aliases
fi

# Set default editor
# export EDITOR=nano
export EDITOR=vim

# Improve the cd command
# 'cd -' to go back to the previous directory
# 'cd' alone to go to the home directory
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Function to create a directory and enter it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# History: do not save duplicate commands and commands starting with space
HISTCONTROL=ignoreboth
HISTIGNORE='ls:ll:la:l:cd:pwd:clear:history:rm:mv:cp:mkdir:touch:chmod:chown:chgrp:ln:mkdir'

# History size
HISTSIZE=50000
HISTFILESIZE=100000

# Append to the history file, don't overwrite it
shopt -s histappend
PROMPT_COMMAND='history -a; history -c; history -r; '"$PROMPT_COMMAND"

# Check the window size after each command
shopt -s checkwinsize

# Improve terminal experience
shopt -s autocd   # Change to a directory by just typing its name
shopt -s cdspell  # Autocorrect minor typos in cd
shopt -s dirspell # Autocorrect typos in directory names during autocompletion
shopt -s globstar # Enable ** pattern to match all files and directories recursively

# Enable autocompletion if available
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Additional useful aliases
ports_func() {
    if command -v netstat &>/dev/null; then
        netstat -tulpen
    elif command -v ss &>/dev/null; then
        ss -tulpen
    else
        echo "No netstat or ss command found"
    fi
}
apply_bashrc() {
    if [ -n "$BASH_VERSION" ]; then
        [ -f "${HOME}/.bashrc" ] && . "${HOME}/.bashrc"
        hash -r
        echo "Bash configuration reloaded"
    elif [ -n "$ZSH_VERSION" ]; then
        [ -f "${HOME}/.zshrc" ] && . "${HOME}/.zshrc"
        hash -r
        echo "Zsh configuration reloaded"
    else
        echo "Unsupported shell"
    fi
}
alias free='free -h'
alias df='df -h'
alias du='du -h'
alias ports='ports_func'
alias publip='curl -m 5 -fsS https://ipinfo.io/ip || curl -m 5 -fsS https://ifconfig.me || curl -m 5 -fsS https://api.ipify.org; echo'
alias privip='hostname -I 2>/dev/null | awk "{print \$1}" || ip -4 addr show scope global | awk '\''/inet /{print $2}'\'' | cut -d/ -f1 | head -n1'
alias clearhistory='history -c && history -w'
alias reloadsh='apply_bashrc'

# History with date and time
export HISTTIMEFORMAT="%d/%m/%y %T "

# Function to search in history
function hg() {
  history | grep "$1"
}

# Function to easily extract compressed files (safer and broader)
extract() {
  if [ -f "$1" ]; then
    case "$1" in
    *.tar.bz2) tar xjf -- "$1" ;;
    *.tar.gz)  tar xzf -- "$1" ;;
    *.tar.zst) tar --zstd -xf -- "$1" ;;
    *.bz2)     bunzip2 -- "$1" ;;
    *.rar)     unrar e -- "$1" ;;
    *.gz)      gunzip -- "$1" ;;
    *.tar)     tar xf -- "$1" ;;
    *.tbz2)    tar xjf -- "$1" ;;
    *.tgz)     tar xzf -- "$1" ;;
    *.zip)     unzip -- "$1" ;;
    *.Z)       uncompress -- "$1" ;;
    *.7z)      7z x -- "$1" ;;
    *.zst)     zstd -d -- "$1" ;;
    *) echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# System information at terminal startup
system_info() {
  # Colors
  local RED="\033[1;31m"
  local GREEN="\033[1;32m"
  local YELLOW="\033[1;33m"
  local BLUE="\033[1;34m"
  local PURPLE="\033[1;35m"
  local CYAN="\033[1;36m"
  local WHITE="\033[1;37m"
  local RESET="\033[0m"
  local BOLD="\033[1m"

  echo -e "${RED}${BOLD}────────────── Distribution Information ──────────────${RESET}"
  printf "${WHITE}%-12s :${RESET} %s\n" "Date/Time" "$(date '+%Y-%m-%d %H:%M:%S')"
  printf "${PURPLE}%-12s :${RESET} %s\n" "User" "$(whoami)@$(cat /etc/hostname)"

  # Distribution and kernel
  local DISTRO=""
  if [ -f /etc/os-release ]; then
    DISTRO=$(grep -w "PRETTY_NAME" /etc/os-release | cut -d= -f2 | tr -d '"')
  fi
  printf "${BLUE}%-12s :${RESET} %s\n" "Distro" "${DISTRO:-Unknown}"
  printf "${RED}%-12s :${RESET} %s\n" "Kernel" "$(uname -r)"

  # Uptime
  printf "${GREEN}%-12s :${RESET} %s\n" "Uptime" "$(uptime -p | sed 's/up //')"

  # Memory and disk usage (root)
  printf "${YELLOW}%-12s :${RESET} %s\n" "Memory" "$(free -h | awk '/^Mem:/ {print $3 " of " $2 " used (" int($3/$2*100) "%)"}')"
  printf "${PURPLE}%-12s :${RESET} %s\n" "Disk (/)" "$(df -h --output=used,size,pcent / | awk 'NR==2 {print $1 " of " $2 " used (" $3 ")"}')"

  # IP addresses
  local LOCAL_IP
  LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
  printf "${CYAN}%-12s :${RESET} %s\n" "Local IP" "${LOCAL_IP:-N/A}"
  echo ""
}
# Alias for system_info
alias sinfo=system_info
alias osinfo=system_info

# Help function - Shows all features and capabilities of this bashrc
bashrc_help() {
  local BOLD='\033[1m'
  local GREEN='\033[0;32m'
  local BLUE='\033[0;34m'
  local CYAN='\033[0;36m'
  local YELLOW='\033[1;33m'
  local RED='\033[0;31m'
  local PURPLE='\033[0;35m'
  local RESET='\033[0m'

  echo -e "${BOLD}${BLUE}===============================================${RESET}"
  echo -e "${BOLD}${GREEN}    Enhanced Bash Configuration Help${RESET}"
  echo -e "${BOLD}${BLUE}===============================================${RESET}"
  echo ""
  echo -e "${BOLD}${CYAN}AUTHOR:${RESET} villcabo"
  echo -e "${BOLD}${CYAN}REPO:${RESET} github.com/villcabo/docker-color-output-install"
  echo ""

  echo -e "${BOLD}${YELLOW}🎨 PROMPT FEATURES:${RESET}"
  echo -e "  ${GREEN}•${RESET} Color-coded by user privilege level:"
  echo -e "    ${RED}•${RESET} Root user: Red prompt (security awareness)"
  echo -e "    ${GREEN}•${RESET} Normal user: Green prompt"
  echo -e "  ${GREEN}•${RESET} Current directory display with colors"
  echo -e "  ${GREEN}•${RESET} Username@hostname format"
  echo ""

  echo -e "${BOLD}${YELLOW}📚 HISTORY ENHANCEMENTS:${RESET}"
  echo -e "  ${GREEN}•${RESET} Timestamps in history (HISTTIMEFORMAT)"
  echo -e "  ${GREEN}•${RESET} Duplicate command removal (HISTCONTROL=ignoreboth)"
  echo -e "  ${GREEN}•${RESET} Large history size (50,000 lines)"
  echo -e "  ${GREEN}•${RESET} Command filtering (ignores common commands)"
  echo -e "  ${GREEN}•${RESET} Immediate history appending"
  echo -e "  ${GREEN}•${RESET} History search with hg function"
  echo ""

  echo -e "${BOLD}${YELLOW}🎯 BUILT-IN ALIASES:${RESET}"
  echo -e "  ${CYAN}File listings:${RESET}"
  echo -e "    ls, ll, la, l    - Enhanced colorized directory listings"
  echo -e "    ll               - Detailed format with -alF flags"
  echo -e "  ${CYAN}Text searching:${RESET}"
  echo -e "    grep, fgrep, egrep  - Colorized search commands"
  echo -e "    fgrepn, egrepn      - Non-colored versions"
  echo -e "  ${CYAN}Navigation:${RESET}"
  echo -e "    ..               - Go up one directory"
  echo -e "    ...              - Go up two directories"
  echo -e "    ....             - Go up three directories"
  echo -e "    .....            - Go up four directories"
  echo -e "  ${CYAN}System info:${RESET}"
  echo -e "    free, df, du     - Human-readable output"
  echo -e "    ports            - Smart port detection (netstat/ss)"
  echo -e "    publip           - Show public IP address"
  echo -e "    privip           - Show private IP address"
  echo -e "    sinfo, osinfo    - System information summary"
  echo -e "  ${CYAN}Utilities:${RESET}"
  echo -e "    clearhistory     - Clear command history"
  echo -e "    reloadsh         - Reload bash configuration"
  echo ""

  echo -e "${BOLD}${YELLOW}🛠️ BUILT-IN FUNCTIONS:${RESET}"
  echo -e "  ${GREEN}•${RESET} ${CYAN}extract <file>${RESET}     - Universal file extractor"
  echo -e "    Supports: zip, tar, gz, bz2, rar, 7z, zst, etc."
  echo -e "  ${GREEN}•${RESET} ${CYAN}mkcd <directory>${RESET}   - Create directory and enter it"
  echo -e "  ${GREEN}•${RESET} ${CYAN}hg <pattern>${RESET}       - Search command history"
  echo -e "  ${GREEN}•${RESET} ${CYAN}system_info${RESET}        - Show basic system information"
  echo -e "    Date/time, user, distro, kernel, uptime, memory, disk, IP"
  echo -e "  ${GREEN}•${RESET} ${CYAN}apply_bashrc${RESET}       - Reload bash/zsh configuration"
  echo -e "  ${GREEN}•${RESET} ${CYAN}ports_func${RESET}         - Smart port listing (netstat/ss)"
  echo -e "  ${GREEN}•${RESET} ${CYAN}bashrc_help${RESET}        - Show this help (you're here!)"
  echo ""

  echo -e "${BOLD}${YELLOW}⚙️ SHELL IMPROVEMENTS:${RESET}"
  echo -e "  ${GREEN}•${RESET} Case-insensitive tab completion"
  echo -e "  ${GREEN}•${RESET} Spell checking for directory names (cdspell, dirspell)"
  echo -e "  ${GREEN}•${RESET} Recursive globbing with ** pattern"
  echo -e "  ${GREEN}•${RESET} Auto-cd by just typing directory name"
  echo -e "  ${GREEN}•${RESET} Enhanced PATH with ~/.local/bin and ~/bin"
  echo -e "  ${GREEN}•${RESET} Vim as default editor"
  echo -e "  ${GREEN}•${RESET} Automatic bash completion loading"
  echo -e "  ${GREEN}•${RESET} Window size checking after each command"
  echo ""

  echo -e "${BOLD}${YELLOW}🎨 COLOR FEATURES:${RESET}"
  echo -e "  ${GREEN}•${RESET} Colorized ls output with dircolors support"
  echo -e "  ${GREEN}•${RESET} Color-coded file types and permissions"
  echo -e "  ${GREEN}•${RESET} Enhanced grep with colors"
  echo -e "  ${GREEN}•${RESET} Color-coded prompt based on user privileges"
  echo -e "  ${GREEN}•${RESET} Custom dircolors support (~/.dircolors)"
  echo ""

  echo -e "${BOLD}${YELLOW}📋 USAGE EXAMPLES:${RESET}"
  echo -e "  ${CYAN}extract project.tar.gz${RESET}   - Extract any supported archive"
  echo -e "  ${CYAN}mkcd new_project${RESET}         - Create and enter directory"
  echo -e "  ${CYAN}hg docker${RESET}                - Search history for 'docker'"
  echo -e "  ${CYAN}sinfo${RESET}                    - Quick system overview"
  echo -e "  ${CYAN}ports${RESET}                    - See what's listening on ports"
  echo -e "  ${CYAN}publip${RESET}                   - Get your public IP"
  echo -e "  ${CYAN}clearhistory${RESET}             - Clean command history"
  echo -e "  ${CYAN}reloadsh${RESET}                 - Reload after making changes"
  echo ""

  echo -e "${BOLD}${YELLOW}📥 INSTALLATION:${RESET}"
  echo -e "  ${GREEN}Direct download:${RESET}"
  echo -e "    ${CYAN}wget https://raw.githubusercontent.com/villcabo/docker-color-output-install/main/bash_configuration/bash_full.sh -O ~/.bashrc${RESET}"
  echo -e "    ${CYAN}source ~/.bashrc${RESET}"
  echo -e "  ${GREEN}Using installer:${RESET}"
  echo -e "    ${CYAN}wget https://raw.githubusercontent.com/villcabo/docker-color-output-install/main/docker_configuration/dcsimpleinstaller.sh${RESET}"
  echo -e "    ${CYAN}chmod +x dcsimpleinstaller.sh && ./dcsimpleinstaller.sh install${RESET}"
  echo ""

  echo -e "${BOLD}${YELLOW}🔧 INTEGRATION:${RESET}"
  echo -e "  ${GREEN}•${RESET} Loads ~/.bash_aliases if present"
  echo -e "  ${GREEN}•${RESET} Compatible with Docker Color Aliases"
  echo -e "  ${GREEN}•${RESET} Works with most Linux distributions"
  echo -e "  ${GREEN}•${RESET} WSL/WSL2 compatible"
  echo -e "  ${GREEN}•${RESET} Server and desktop environment friendly"
  echo ""

  echo -e "${BOLD}${BLUE}===============================================${RESET}"
  echo -e "${BOLD}${GREEN}Run 'bashrc_help' anytime to see this help!${RESET}"
  echo -e "${BOLD}${BLUE}===============================================${RESET}"
}
# Aliases for help
alias bhelp='bashrc_help'
alias bashhelp='bashrc_help'
