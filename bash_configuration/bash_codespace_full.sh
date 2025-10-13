#!/bin/bash
# ==============================================================
# Enhanced Bash Configuration for Codespaces (bash_codespace_full.sh)
# ==============================================================
#
# AUTHOR: villcabo
# REPOSITORY: https://github.com/villcabo/docker-color-output-install
# VERSION: 1.0
# CREATED: October 2025
#
# DESCRIPTION:
# Advanced bash configuration specifically optimized for GitHub Codespaces
# and development environments with enhanced features including:
# - Dynamic prompt with Git integration and GitHub user detection
# - Advanced system information display with detailed metrics
# - Development-focused aliases and utilities
# - Terminal title management for better workflow
# - Comprehensive system monitoring and status reporting
# - Weather integration and network utilities
#
# FEATURES:
# - GitHub Codespaces optimized prompt with Git branch and status
# - Dynamic terminal titles showing current command execution
# - Comprehensive system information (CPU, memory, network, services)
# - Git integration with dirty status detection
# - Root/user awareness with color-coded prompts
# - Advanced file extraction utilities
# - Network and system monitoring aliases
# - Last login tracking and user session information
#
# CODESPACES SPECIFIC:
# - GitHub user detection and display
# - Dev container theme compatibility
# - Git status integration in prompt
# - Development workflow optimizations
# - Container-aware system information
#
# USAGE:
# This file is specifically designed for GitHub Codespaces and development
# containers. Can also be used in any development environment.
# Run 'codespace_help', 'chelp', or 'codehelp' after installation to see all features.
#
# INSTALLATION:
# Download the latest version from GitHub repository:
# wget https://raw.githubusercontent.com/villcabo/docker-color-output-install/main/bash_configuration/bash_codespace_full.sh -O ~/.bashrc
# source ~/.bashrc
#
# Alternative installation using dcsimpleinstaller:
# wget https://raw.githubusercontent.com/villcabo/docker-color-output-install/main/docker_configuration/dcsimpleinstaller.sh
# chmod +x dcsimpleinstaller.sh
# ./dcsimpleinstaller.sh install
#
# COMPATIBILITY:
# - Bash 4.0+
# - GitHub Codespaces
# - Dev Containers
# - Docker development environments
# - Linux distributions (Ubuntu, Debian, CentOS, etc.)
# - Windows WSL/WSL2
#
# ==============================================================

# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
esac

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
xterm-color | *-256color) color_prompt=yes ;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
  if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    # We have color support; assume it's compliant with Ecma-48
    # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
    # a case would tend to support setf rather than setaf.)
    color_prompt=yes
  else
    color_prompt=
  fi
fi

if [ "$color_prompt" = yes ]; then
  PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
  PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm* | rxvt*)
  PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
  ;;
*) ;;
esac

# bash theme - partly inspired by https://github.com/ohmyzsh/ohmyzsh/blob/master/themes/robbyrussell.zsh-theme
__bash_prompt() {
  local userpart='`export XIT=$? \
    && [ "$EUID" -eq 0 ] && echo -n "\[\033[1;31m\]\u\[\033[1;33m\]@\[\033[1;31m\]\h\[\033[0m\] " || \
    ([ ! -z "${GITHUB_USER:-}" ] && echo -n "\[\033[1;32m\]@${GITHUB_USER:-}\[\033[1;33m\]@\[\033[1;32m\]\h\[\033[0m\] " || echo -n "\[\033[1;32m\]\u\[\033[1;33m\]@\[\033[1;32m\]\h\[\033[0m\] ") \
    && [ "$XIT" -ne "0" ] && echo -n "\[\033[1;31m\]➜" || echo -n "\[\033[0m\]➜"`'
  local gitbranch='`\
    if [ "$(git config --get devcontainers-theme.hide-status 2>/dev/null)" != 1 ] && [ "$(git config --get codespaces-theme.hide-status 2>/dev/null)" != 1 ]; then \
        export BRANCH="$(git --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || git --no-optional-locks rev-parse --short HEAD 2>/dev/null)"; \
        if [ "${BRANCH:-}" != "" ]; then \
            echo -n "\[\033[0;36m\](\[\033[1;31m\]${BRANCH:-}" \
            && if [ "$(git config --get devcontainers-theme.show-dirty 2>/dev/null)" = 1 ] && \
                git --no-optional-locks ls-files --error-unmatch -m --directory --no-empty-directory -o --exclude-standard ":/*" > /dev/null 2>&1; then \
                    echo -n " \[\033[1;33m\]✗"; \
            fi \
            && echo -n "\[\033[0;36m\]) "; \
        fi; \
    fi`'
  local lightblue='\[\033[1;34m\]'
  local removecolor='\[\033[0m\]'
  PS1="${userpart} ${lightblue}\w ${gitbranch}${removecolor}\$ "
  unset -f __bash_prompt
}
__bash_prompt
export PROMPT_DIRTRIM=4

# Check if the terminal is xterm
if [[ "$TERM" == "xterm" ]]; then
  # Function to set the terminal title to the current command
  preexec() {
    local cmd="${BASH_COMMAND}"
    echo -ne "\033]0;${USER}@${HOSTNAME}: ${cmd}\007"
  }

  # Function to reset the terminal title to the shell type after the command is executed
  precmd() {
    echo -ne "\033]0;${USER}@${HOSTNAME}: ${SHELL}\007"
  }

  # Trap DEBUG signal to call preexec before each command
  trap 'preexec' DEBUG

  # Append to PROMPT_COMMAND to call precmd before displaying the prompt
  PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }precmd"
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
if [ -f ~/.bash_aliases ]; then
  . ~/.bash_aliases
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
# Aliases for system_info
alias sinfo='system_info'
alias osinfo='system_info'

# Help function - Shows all features and capabilities of this codespace bashrc
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
  echo -e "${BOLD}${GREEN}   Enhanced Bash Configuration for Codespaces${RESET}"
  echo -e "${BOLD}${BLUE}===============================================${RESET}"
  echo ""
  echo -e "${BOLD}${CYAN}AUTHOR:${RESET} villcabo"
  echo -e "${BOLD}${CYAN}REPO:${RESET} github.com/villcabo/docker-color-output-install"
  echo ""

  echo -e "${BOLD}${YELLOW}🎨 PROMPT FEATURES:${RESET}"
  echo -e "  ${GREEN}•${RESET} Color-coded prompt with hostname visibility"
  echo -e "  ${GREEN}•${RESET} Root user: ${RED}root${CYAN}@hostname${RESET} (red/cyan/blue colors)"
  echo -e "  ${GREEN}•${RESET} Regular user: ${GREEN}user${CYAN}@hostname${RESET} (green/cyan/blue colors)"
  echo -e "  ${GREEN}•${RESET} GitHub user detection: ${GREEN}@GITHUB_USER${CYAN}@hostname${RESET}"
  echo -e "  ${GREEN}•${RESET} Git branch integration with dirty status indicators"
  echo -e "  ${GREEN}•${RESET} Exit status indicators (red ➜ for errors, normal ➜ for success)"
  echo -e "  ${GREEN}•${RESET} Terminal title management with dynamic command display"
  echo -e "  ${GREEN}•${RESET} Current directory display"
  echo -e "  ${GREEN}•${RESET} Support for debian_chroot display"
  echo ""

  echo -e "${BOLD}${YELLOW}📚 HISTORY ENHANCEMENTS:${RESET}"
  echo -e "  ${GREEN}•${RESET} Timestamps in history (HISTTIMEFORMAT)"
  echo -e "  ${GREEN}•${RESET} Duplicate command removal"
  echo -e "  ${GREEN}•${RESET} Large history size (50,000 lines)"
  echo -e "  ${GREEN}•${RESET} Immediate history appending"
  echo -e "  ${GREEN}•${RESET} History search with hg function"
  echo ""

  echo -e "${BOLD}${YELLOW}� BUILT-IN ALIASES:${RESET}"
  echo -e "  ${CYAN}File listings:${RESET}"
  echo -e "    ls, ll, la, l    - Enhanced colorized directory listings"
  echo -e "    ll               - Detailed format with -alF"
  echo -e "  ${CYAN}Navigation:${RESET}"
  echo -e "    ..               - Go up one directory"
  echo -e "    ...              - Go up two directories"
  echo -e "    ....             - Go up three directories"
  echo -e "    .....            - Go up four directories"
  echo -e "  ${CYAN}System info:${RESET}"
  echo -e "    free, df, du     - Human-readable output"
  echo -e "    ports            - Show open ports (ss -tulpen)"
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
  echo -e "  ${GREEN}•${RESET} ${CYAN}system_info${RESET}        - Show detailed system information"
  echo -e "  ${GREEN}•${RESET} ${CYAN}apply_bashrc${RESET}       - Reload bash configuration"
  echo -e "  ${GREEN}•${RESET} ${CYAN}bashrc_help${RESET}        - Show this help (you're here!)"
  echo ""

  echo -e "${BOLD}${YELLOW}⚙️ SHELL IMPROVEMENTS:${RESET}"
  echo -e "  ${GREEN}•${RESET} Case-insensitive tab completion"
  echo -e "  ${GREEN}•${RESET} Spell checking for directory names (cdspell, dirspell)"
  echo -e "  ${GREEN}•${RESET} Recursive globbing with ** pattern"
  echo -e "  ${GREEN}•${RESET} Auto-cd by just typing directory name"
  echo -e "  ${GREEN}•${RESET} Enhanced PATH with local bin directories"
  echo -e "  ${GREEN}•${RESET} Vim as default editor"
  echo -e "  ${GREEN}•${RESET} Automatic bash completion loading"
  echo ""

  echo -e "${BOLD}${YELLOW}🎨 COLOR FEATURES:${RESET}"
  echo -e "  ${GREEN}•${RESET} Colorized ls output with dircolors"
  echo -e "  ${GREEN}•${RESET} Color-coded file types"
  echo -e "  ${GREEN}•${RESET} Enhanced grep with colors (grep, fgrep, egrep)"
  echo -e "  ${GREEN}•${RESET} Color-coded prompt"
  echo -e "  ${GREEN}•${RESET} Optional color-free versions (fgrepn, egrepn)"
  echo ""

  echo -e "${BOLD}${YELLOW}🖥️ TERMINAL ENHANCEMENTS:${RESET}"
  echo -e "  ${GREEN}•${RESET} Dynamic terminal titles showing current command"
  echo -e "  ${GREEN}•${RESET} Terminal title reset after command completion"
  echo -e "  ${GREEN}•${RESET} Support for xterm terminal features"
  echo -e "  ${GREEN}•${RESET} Intelligent interactive detection"
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
  echo -e "    ${CYAN}wget https://raw.githubusercontent.com/villcabo/docker-color-output-install/main/bash_configuration/bash_codespace_full.sh -O ~/.bashrc${RESET}"
  echo -e "    ${CYAN}source ~/.bashrc${RESET}"
  echo -e "  ${GREEN}Using installer:${RESET}"
  echo -e "    ${CYAN}wget https://raw.githubusercontent.com/villcabo/docker-color-output-install/main/docker_configuration/dcsimpleinstaller.sh${RESET}"
  echo -e "    ${CYAN}chmod +x dcsimpleinstaller.sh && ./dcsimpleinstaller.sh install${RESET}"
  echo ""

  echo -e "${BOLD}${YELLOW}🔧 INTEGRATION:${RESET}"
  echo -e "  ${GREEN}•${RESET} Optimized for GitHub Codespaces"
  echo -e "  ${GREEN}•${RESET} Compatible with Dev Containers"
  echo -e "  ${GREEN}•${RESET} Loads ~/.bash_aliases if present"
  echo -e "  ${GREEN}•${RESET} Works with most Linux distributions"
  echo -e "  ${GREEN}•${RESET} WSL/WSL2 compatible"
  echo ""

  echo -e "${BOLD}${BLUE}===============================================${RESET}"
  echo -e "${BOLD}${GREEN}Run 'bashrc_help' anytime to see this help!${RESET}"
  echo -e "${BOLD}${BLUE}===============================================${RESET}"
}

# Aliases for help
alias bhelp='bashrc_help'
alias bashhelp='bashrc_help'
