#!/usr/bin/env bash

# ==============================================================
# Docker Color Aliases - Enhanced and Simplified Version v2
# ==============================================================
#
# A comprehensive Docker and Docker Compose aliases collection that provides:
# - Simplified commands with intelligent shortcuts (d, dc)
# - Smart confirmation dialogs for destructive operations
# - Enhanced autocompletion for containers and services
# - Flexible compose file detection (docker-compose.yml, custom via DOCKER_COMPOSE_FILE)
# - Color-coded output integration with docker-color-output
# - Quick execution functions (dq, dcq) for pattern matching
# - Comprehensive help system and status reporting
#
# USAGE:
#   Source this file in your shell profile:
#   [[ -s "$HOME/.docker_color_settings" ]] && source "$HOME/.docker_color_settings"
#
# MAIN COMMANDS:
#   d [command]     - Docker shortcuts (ps, logs, exec, etc.)
#   dc [command]    - Docker Compose shortcuts (up, down, logs, etc.)
#   dq [pattern]    - Quick exec in first matching container
#   dcq [pattern]   - Quick exec in first matching service
#   dstatus         - Show containers and services status
#   dhelp/dchelp    - Show detailed help
#
# EXAMPLES:
#   d ps            - List running containers
#   dc up -pl       - Start services with pull and logs
#   dc up -f compose.prod.yml  - Start services using specific compose file
#   dc up --force   - Start services with force recreate
#   dc down -f compose.dev.yml - Stop services using specific compose file
#   dc build -f compose.test.yml - Build services using specific compose file
#   dc default compose.yml      - Set default compose file
#   dc default remove           - Remove default compose file setting
#   dc info                     - Show compose configuration and status
#   dq web bash     - Execute bash in first container matching 'web'
#   dc x api bash   - Execute bash in 'api' service
#
# CONFIGURATION:
#   DOCKER_COMPOSE_FILE - Custom compose file path (default: docker-compose.yml)
#
# DEPENDENCIES:
#   - docker, docker compose
#   - docker-color-output (optional, for colored output)
#   - bash completion support
#
# AUTHOR: villcabo
# REPOSITORY: https://github.com/villcabo/docker-color-output-install
# ==============================================================

# Color variables
CR="\033[0m"        # COLOR_RESET
CRE="\033[1;31m"    # COLOR_RED
CGR="\033[1;32m"    # COLOR_GREEN
CYE="\033[1;33m"    # COLOR_YELLOW
CBL="\033[1;34m"    # COLOR_BLUE
CMA="\033[1;35m"    # COLOR_MAGENTA
CCY="\033[1;36m"    # COLOR_CYAN
CWH="\033[1;37m"    # COLOR_WHITE

# Text styles
CB="\033[1m"        # BOLD
CI="\033[3m"        # ITALIC
CU="\033[4m"        # UNDERLINE

# Compose file detection
_get_compose_file() {
    # Check for custom compose file from environment variable
    if [[ -n "$DOCKER_COMPOSE_FILE" && -f "$DOCKER_COMPOSE_FILE" ]]; then
        echo "$DOCKER_COMPOSE_FILE"
        return 0
    fi

    # Default priority: docker-compose.yml > docker-compose.yaml
    if [[ -f docker-compose.yml ]]; then
        echo "docker-compose.yml"
        return 0
    elif [[ -f docker-compose.yaml ]]; then
        echo "docker-compose.yaml"
        return 0
    fi

    return 1
}

# Confirmation function
_confirm_operation() {
    local message="${1:-Continue with operation?}"
    printf "${CB}${CRE}${message} [yes/N]: ${CR}"
    read -r response
    [[ "$response" == "yes" ]]
}

# Main function for docker with subcommands
d() {
    case "$1" in
        # Basic commands
        ps|p)     shift; docker ps "$@" | docker-color-output ;;
        ps1|p1)   shift; docker ps --format "table {{.ID}}\\t{{.Names}}\\t{{.RunningFor}}\\t{{.Status}}\\t{{.Image}}" "$@" | docker-color-output ;;
        psp)      shift; docker ps --format "table {{.ID}}\\t{{.Names}}\\t{{.Ports}}" "$@" | docker-color-output ;;
        images|i) shift; docker images "$@" | docker-color-output ;;

        # Stats and logs
        stats|s)  shift; docker stats "$@" | docker-color-output ;;
        s1)       shift; docker stats --no-stream "$@" | docker-color-output ;;
        logs|l)   shift; docker logs -f "$@" ;;
        l100)     shift; docker logs --tail 100 -f "$@" ;;
        l300)     shift; docker logs --tail 300 -f "$@" ;;
        l500)     shift; docker logs --tail 500 -f "$@" ;;

        # Exec (simplified)
        x)        shift; docker exec -it "$@" ;;
        sh)       shift; docker exec -it "$1" sh ;;
        bash)     shift; docker exec -it "$1" bash ;;

        # Container control
        start)    shift; docker start "$@" ;;
        stop)     shift; docker stop "$@" ;;
        restart)  shift; docker restart "$@" ;;
        rm)       shift; docker rm "$@" ;;
        rmi)      shift; docker rmi "$@" ;;
        kill)     shift; docker kill "$@" ;;

        # Information
        inspect)  shift; docker inspect "$@" ;;
        top)      shift; docker top "$@" ;;

        # Cleanup
        prune|pr)    docker system prune -f ;;
        prunea|prf)   docker system prune -af ;;
        pruneima|pri) docker image prune -f ;;
        prunevol|prv) docker volume prune -f ;;
        prunenet|prn) docker network prune -f ;;

        # Help
        help|h)   _docker_help ;;

        # Default: pass command directly to docker
        *)        docker "$@" ;;
    esac
}

# Main function for docker compose with subcommands
dc() {
    # Check for compose file first
    local compose_file=$(_get_compose_file)
    if [[ $? -ne 0 ]]; then
        echo -e "${CRE}No compose file found. Expected ${CB}docker-compose.yml${CR}, ${CB}docker-compose.yaml${CR}, or set ${CB}DOCKER_COMPOSE_FILE${CR} environment variable ❌${CR}"
        return 1
    fi

    case "$1" in
        # Up with smart options
        up|u)
            shift
            local opts=""
            local show_logs=false
            local services=()
            local custom_file=""

            # Parse flags and services
            while [[ $# -gt 0 ]]; do
                if [[ $1 == -* ]]; then
                    if [[ $1 == "-f" && -n "$2" && $2 != -* ]]; then
                        # -f followed by filename
                        custom_file="$2"
                        shift 2
                        continue
                    elif [[ $1 == "--force" ]]; then
                        opts+=" --force-recreate"
                        shift
                        continue
                    else
                        local flags="${1#-}"
                        for ((i=0; i<${#flags}; i++)); do
                            case "${flags:$i:1}" in
                                p) opts+=" --pull always" ;;
                                b) opts+=" --build" ;;
                                l) show_logs=true ;;
                            esac
                        done
                    fi
                else
                    services+=("$1")
                fi
                shift
            done

            # Use custom file if specified, otherwise use detected compose file
            if [[ -n "$custom_file" ]]; then
                if [[ ! -f "$custom_file" ]]; then
                    echo -e "${CRE}Custom compose file ${CB}$custom_file${CR} not found ❌"
                    return 1
                fi
                compose_file="$custom_file"
            fi

            # Get available services
            local all_services=($(_get_compose_services))
            local target_services=()

            if [[ ${#services[@]} -eq 0 ]]; then
                target_services=("${all_services[@]}")
            else
                target_services=("${services[@]}")
            fi

            # Show confirmation with colors
            echo -e "${CB}${CYE}DOCKER COMPOSE UP${CR} 🐳"
            echo -e "${CCY}Action:${CR} Start Docker Compose services"
            echo -e "${CCY}Compose file:${CR} ${CB}$compose_file${CR}"
            if [[ -n "$opts" ]]; then
                echo -e "${CCY}Options:${CR}${CB}$opts${CR}"
            fi
            echo -e "${CCY}Affected services:${CR} ${CB}${CGR}${target_services[*]}${CR}"
            if [[ "$show_logs" == true ]]; then
                echo -e "${CCY}Additional action:${CR} ${CB}Show logs after up${CR}"
            fi
            echo ""
            if _confirm_operation "Continue with operation?"; then
                local cmd="docker compose -f \"$compose_file\" up -d$opts"
                if [[ ${#services[@]} -gt 0 ]]; then
                    cmd+=" ${services[*]}"
                fi

                if eval "$cmd"; then
                    if [[ "$show_logs" == true ]]; then
                        if [[ ${#services[@]} -gt 0 ]]; then
                            docker compose -f "$compose_file" logs -f "${services[@]}"
                        else
                            docker compose -f "$compose_file" logs -f
                        fi
                    fi
                fi
            else
                echo -e "${CB}${CYE}Operation cancelled${CR} ⚠️"
                return 1
            fi
            ;;

        # Up con logs automáticos
        ul)       shift; docker compose -f "$compose_file" up -d "$@" && docker compose -f "$compose_file" logs -f "$@" ;;

        # Básicos
        ps|p)     shift; docker compose -f "$compose_file" ps "$@" | docker-color-output ;;
        ps1|p1)   shift; docker compose -f "$compose_file" ps --format "table {{.Name}}\\t{{.Service}}\\t{{.RunningFor}}\\t{{.Status}}\\t{{.Image}}" "$@" | docker-color-output ;;
        psp)      shift; docker compose -f "$compose_file" ps --format "table {{.Name}}\\t{{.Service}}\\t{{.Ports}}" "$@" | docker-color-output ;;

        # Stats y logs
        stats|s)  shift; docker compose -f "$compose_file" stats "$@" | docker-color-output ;;
        s1)       shift; docker compose -f "$compose_file" stats --no-stream "$@" | docker-color-output ;;
        logs|l)   shift; docker compose -f "$compose_file" logs --tail 100 -f "$@" ;;
        l100)     shift; docker compose -f "$compose_file" logs --tail 100 -f "$@" ;;
        l300)     shift; docker compose -f "$compose_file" logs --tail 300 -f "$@" ;;
        l500)     shift; docker compose -f "$compose_file" logs --tail 500 -f "$@" ;;

        # Exec (más simple)
        x)        shift; docker compose -f "$compose_file" exec "$@" ;;
        sh)       shift; docker compose -f "$compose_file" exec "$1" sh ;;
        bash)     shift; docker compose -f "$compose_file" exec "$1" bash ;;

        # Control de servicios
        down|d)
            shift
            local services=()
            local custom_file=""
            local opts=""

            # Parse flags and services
            while [[ $# -gt 0 ]]; do
                if [[ $1 == "-f" && -n "$2" && $2 != -* ]]; then
                    # -f followed by filename
                    custom_file="$2"
                    shift 2
                    continue
                else
                    if [[ $1 == -* ]]; then
                        opts+=" $1"
                    else
                        services+=("$1")
                    fi
                fi
                shift
            done

            # Use custom file if specified, otherwise use detected compose file
            if [[ -n "$custom_file" ]]; then
                if [[ ! -f "$custom_file" ]]; then
                    echo -e "${CRE}Custom compose file ${CB}$custom_file${CR} not found ❌"
                    return 1
                fi
                compose_file="$custom_file"
            fi

            # Get available services for preview
            local all_services=($(_get_compose_services))
            local target_services=()

            if [[ ${#services[@]} -eq 0 ]]; then
                target_services=("${all_services[@]}")
            else
                target_services=("${services[@]}")
            fi

            # Show confirmation with colors
            echo -e "${CB}${CRE}DOCKER COMPOSE DOWN${CR} 🛑"
            echo -e "${CCY}Action:${CR} Stop and remove Docker Compose services"
            echo -e "${CCY}Compose file:${CR} ${CB}$compose_file${CR}"
            if [[ -n "$opts" ]]; then
                echo -e "${CCY}Options:${CR}${CB}$opts${CR}"
            fi
            echo -e "${CCY}Affected services:${CR} ${CB}${CGR}${target_services[*]}${CR}"
            echo ""
            if _confirm_operation "Continue with operation?"; then
                local cmd="docker compose -f \"$compose_file\" down$opts"
                if [[ ${#services[@]} -gt 0 ]]; then
                    cmd+=" ${services[*]}"
                fi
                eval "$cmd"
            else
                echo -e "${CB}${CYE}Operation cancelled${CR} ⚠️"
                return 1
            fi
            ;;
        start)    shift; docker compose -f "$compose_file" start "$@" ;;
        stop)     shift; docker compose -f "$compose_file" stop "$@" ;;
        restart)  shift; docker compose -f "$compose_file" restart "$@" ;;

        # Build y pull
        build|b)
            shift
            local services=()
            local custom_file=""
            local opts=""

            # Parse flags and services
            while [[ $# -gt 0 ]]; do
                if [[ $1 == "-f" && -n "$2" && $2 != -* ]]; then
                    # -f followed by filename
                    custom_file="$2"
                    shift 2
                    continue
                else
                    if [[ $1 == -* ]]; then
                        opts+=" $1"
                    else
                        services+=("$1")
                    fi
                fi
                shift
            done

            # Use custom file if specified, otherwise use detected compose file
            if [[ -n "$custom_file" ]]; then
                if [[ ! -f "$custom_file" ]]; then
                    echo -e "${CRE}Custom compose file ${CB}$custom_file${CR} not found ❌"
                    return 1
                fi
                compose_file="$custom_file"
            fi

            # Get available services for preview
            local all_services=($(_get_compose_services))
            local target_services=()

            if [[ ${#services[@]} -eq 0 ]]; then
                target_services=("${all_services[@]}")
            else
                target_services=("${services[@]}")
            fi

            # Show confirmation with colors
            echo -e "${CB}${CCY}DOCKER COMPOSE BUILD${CR} 🔨"
            echo -e "${CCY}Action:${CR} Build Docker Compose services"
            echo -e "${CCY}Compose file:${CR} ${CB}$compose_file${CR}"
            if [[ -n "$opts" ]]; then
                echo -e "${CCY}Options:${CR}${CB}$opts${CR}"
            fi
            echo -e "${CCY}Affected services:${CR} ${CB}${CGR}${target_services[*]}${CR}"
            echo ""
            if _confirm_operation "Continue with operation?"; then
                local cmd="docker compose -f \"$compose_file\" build$opts"
                if [[ ${#services[@]} -gt 0 ]]; then
                    cmd+=" ${services[*]}"
                fi
                eval "$cmd"
            else
                echo -e "${CB}${CYE}Operation cancelled${CR} ⚠️"
                return 1
            fi
            ;;
        pull)     shift; docker compose -f "$compose_file" pull "$@" ;;

        # Default compose file management
        default)
            shift
            if [[ -z "$1" ]]; then
                # Show current default
                if [[ -f ".env" ]] && grep -q "^DOCKER_COMPOSE_FILE=" .env; then
                    local current_file=$(grep "^DOCKER_COMPOSE_FILE=" .env | cut -d'=' -f2)
                    echo -e "${CGR}Current default Docker Compose file: ${CB}$current_file${CR} 📋"
                else
                    echo -e "${CYE}No default Docker Compose file is currently set${CR} ⚠️"
                fi
            elif [[ "$1" == "remove" || "$1" == "rm" ]]; then
                # Remove default compose file
                if [[ -f ".env" ]] && grep -q "^DOCKER_COMPOSE_FILE=" .env; then
                    # Remove the line from .env
                    sed -i '/^DOCKER_COMPOSE_FILE=/d' .env
                    echo -e "${CGR}Default Docker Compose file removed${CR} ✅"
                else
                    echo -e "${CYE}No default Docker Compose file is currently set${CR} ⚠️"
                fi
            else
                # Set default compose file
                local file="$1"
                if [[ ! -f "$file" ]]; then
                    echo -e "${CRE}File ${CB}$file${CR} does not exist ❌"
                    return 1
                fi

                # Add or update DOCKER_COMPOSE_FILE in .env
                if [[ -f ".env" ]]; then
                    # Remove existing line if present
                    sed -i '/^DOCKER_COMPOSE_FILE=/d' .env
                fi
                echo "DOCKER_COMPOSE_FILE=$file" >> .env
                echo -e "${CGR}Default Docker Compose file set to: ${CB}$file${CR} ✅"
            fi
            ;;

        # Info command to show configuration
        info)
            echo -e "${CB}${CCY}=== DOCKER COMPOSE CONFIGURATION ===${CR}"
            echo -e "${CCY}Working directory:${CR} ${CB}$(pwd)${CR}"

            # Show compose file being used
            local compose_file=$(_get_compose_file)
            if [[ $? -eq 0 ]]; then
                echo -e "${CCY}Active compose file:${CR} ${CB}${CGR}$compose_file${CR}"
            else
                echo -e "${CCY}Active compose file:${CR} ${CRE}None found${CR}"
            fi

            # Show default setting
            if [[ -f ".env" ]] && grep -q "^DOCKER_COMPOSE_FILE=" .env; then
                local default_file=$(grep "^DOCKER_COMPOSE_FILE=" .env | cut -d'=' -f2)
                echo -e "${CCY}Default setting:${CR} ${CB}DOCKER_COMPOSE_FILE=$default_file${CR}"
            else
                echo -e "${CCY}Default setting:${CR} ${CYE}Not configured${CR}"
            fi

            # Show available compose files
            echo -e "${CCY}Available compose files:${CR}"
            local found_files=false
            for file in docker-compose.yml docker-compose.yaml compose.yml compose.yaml *.yml *.yaml; do
                if [[ -f "$file" ]]; then
                    echo -e "  - ${CB}$file${CR}"
                    found_files=true
                fi
            done
            if [[ "$found_files" == false ]]; then
                echo -e "  ${CYE}No compose files found${CR}"
            fi
            ;;

        # Ayuda
        help|h)   _compose_help ;;

        # Por defecto, pasar comando directo a docker compose
        *)        docker compose -f "$compose_file" "$@" ;;        # Ayuda
        help|h)   _compose_help ;;

        # Por defecto, pasar comando directo a docker compose
        *)        docker compose -f "$compose_file" "$@" ;;
    esac
}

# ==============================================================
# Aliases cortos adicionales (backward compatibility)
# ==============================================================

# Los más usados como aliases independientes
alias dps='d ps'
alias dps1='d ps1'
alias di='d images'
alias dl='d logs'
alias dlt='d l100'
alias dpri='d image prune'
alias ds='d stats'

dcup() {
    # Check for compose file first
    local compose_file=$(_get_compose_file)
    if [[ $? -ne 0 ]]; then
        echo -e "${CRE}No compose file found. Expected ${CB}docker-compose.yml${CR}, ${CB}docker-compose.yaml${CR}, or set ${CB}DOCKER_COMPOSE_FILE${CR} environment variable ❌${CR}"
        return 1
    fi

    # Parse arguments to get specific services
    local services=()
    local opts=""
    local show_logs=false
    local custom_file=""

    for arg in "$@"; do
        if [[ $arg == -* ]]; then
            if [[ $arg == "-f" && -n "$2" && $2 != -* ]]; then
                # -f followed by filename
                custom_file="$2"
                shift 2
                continue
            elif [[ $arg == "--force" ]]; then
                opts+=" --force-recreate"
                shift
                continue
            else
                local flags="${arg#-}"
                for ((i=0; i<${#flags}; i++)); do
                    case "${flags:$i:1}" in
                        p) opts+=" --pull always" ;;
                        b) opts+=" --build" ;;
                        l) show_logs=true ;;
                    esac
                done
            fi
        else
            services+=("$arg")
        fi
    done

    # Use custom file if specified, otherwise use detected compose file
    if [[ -n "$custom_file" ]]; then
        if [[ ! -f "$custom_file" ]]; then
            echo -e "${CRE}Custom compose file ${CB}$custom_file${CR} not found ❌"
            return 1
        fi
        compose_file="$custom_file"
    fi

    # Get available services
    local all_services=($(_get_compose_services))
    local target_services=()

    if [[ ${#services[@]} -eq 0 ]]; then
        target_services=("${all_services[@]}")
    else
        target_services=("${services[@]}")
    fi

    # Show confirmation with colors
    echo -e "${CB}${CYE}DOCKER COMPOSE UP${CR} 🐳"
    echo -e "${CCY}Action:${CR} Start Docker Compose services"
    echo -e "${CCY}Compose file:${CR} ${CB}$compose_file${CR}"
    if [[ -n "$opts" ]]; then
        echo -e "${CCY}Options:${CR}${CB}$opts${CR}"
    fi
    echo -e "${CCY}Affected services:${CR} ${CB}${CGR}${target_services[*]}${CR}"
    if [[ "$show_logs" == true ]]; then
        echo -e "${CCY}Additional action:${CR} ${CB}Show logs after up${CR}"
    fi
    echo ""
    if _confirm_operation "Continue with operation?"; then
        local cmd="docker compose -f \"$compose_file\" up -d$opts"
        if [[ ${#services[@]} -gt 0 ]]; then
            cmd+=" ${services[*]}"
        fi

        if eval "$cmd"; then
            if [[ "$show_logs" == true ]]; then
                if [[ ${#services[@]} -gt 0 ]]; then
                    docker compose -f "$compose_file" logs -f "${services[@]}"
                else
                    docker compose -f "$compose_file" logs -f
                fi
            fi
        fi
    else
        echo -e "${CB}${CYE}Operation cancelled${CR} ⚠️"
        return 1
    fi
}

alias dcps='dc ps'
alias dcps1='dc ps1'
alias dcl='dc logs'
alias dcdown='dc down'
alias dcs='dc stats'

# Exec shortcuts (muy comunes)
alias dx='d x'
alias dcx='dc x'

# ====================================================  ==========
# Smart Functions - Intelligent Functions
# ==============================================================

# Function to execute command in the first container that matches
dq() {
    local container=$(docker ps --format "{{.Names}}" | grep -i "$1" | head -1)
    if [[ -n "$container" ]]; then
        echo -e "${CGR}Executing in: ${CB}$container${CR} 🚀"
        shift
        docker exec -it "$container" "$@"
    else
        echo -e "${CRE}No container found matching: ${CB}$1${CR} ❌"
        return 1
    fi
}

# Function to execute command in the first service that matches
dcq() {
    local compose_file=$(_get_compose_file)
    if [[ $? -ne 0 ]]; then
        echo -e "${CRE}No compose file found. Expected ${CB}docker-compose.yml${CR}, ${CB}docker-compose.yaml${CR}, or set ${CB}DOCKER_COMPOSE_FILE${CR} environment variable ❌${CR}"
        return 1
    fi

    local service=$(docker compose -f "$compose_file" ps --services | grep -i "$1" | head -1)
    if [[ -n "$service" ]]; then
        echo -e "${CGR}Executing in service: ${CB}$service${CR} 🚀"
        shift
        docker compose -f "$compose_file" exec "$service" "$@"
    else
        echo -e "${CRE}No service found matching: ${CB}$1${CR} ❌"
        return 1
    fi
}

# Function to show quick status
dstatus() {
    echo -e "${CB}${CCY}=== CONTAINERS ===${CR}"
    docker ps --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}" | docker-color-output

    local compose_file=$(_get_compose_file)
    if [[ $? -eq 0 ]]; then
        echo -e "\n${CB}${CCY}=== COMPOSE SERVICES ===${CR}"
        docker compose -f "$compose_file" ps --format "table {{.Service}}\\t{{.Status}}\\t{{.Ports}}" | docker-color-output
    fi
}

# Function to clean everything at once
dcleanup() {
    echo -e "${CYE}${CB}Cleaning Docker...${CR} 🧹"
    docker system prune -f
    docker network prune -f
    echo -e "${CGR}${CB}Cleanup completed${CR} ✅"
}

# ==============================================================
# Enhanced Autocompletion
# ==============================================================

_get_docker_containers() {
    docker ps --format "{{.Names}}" 2>/dev/null
}

_get_compose_services() {
    local compose_file=$(_get_compose_file)
    if [[ $? -eq 0 ]]; then
        docker compose -f "$compose_file" config --services 2>/dev/null
    fi
}

# Intelligent autocompletion for function d()
_d_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    if [[ ${COMP_CWORD} == 1 ]]; then
        # First arguments - subcommands
        local commands="ps p ps1 p1 psp images i stats s s1 logs l l100 l300 l500 x sh bash start stop restart rm rmi kill inspect top prune prunea prunevol prunenet help h"
        COMPREPLY=($(compgen -W "${commands}" -- ${cur}))
    else
        # Second arguments - containers
        case "$prev" in
            x|sh|bash|logs|l|l100|l300|l500|start|stop|restart|rm|inspect|top)
                local containers=$(_get_docker_containers)
                COMPREPLY=($(compgen -W "${containers}" -- ${cur}))
                ;;
        esac
    fi
}

# Intelligent autocompletion for function dc()
_dc_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    local command=""
    local has_flags=false

    # Find the main command (ignoring flags)
    for ((i=1; i<COMP_CWORD; i++)); do
        if [[ "${COMP_WORDS[i]}" != -* ]]; then
            command="${COMP_WORDS[i]}"
            break
        fi
    done

    # Check if there are already flags in the command line
    for ((i=1; i<COMP_CWORD; i++)); do
        if [[ "${COMP_WORDS[i]}" == -* ]]; then
            has_flags=true
            break
        fi
    done

    if [[ ${COMP_CWORD} == 1 ]]; then
        # First arguments - subcommands
        local commands="up u ul ps p ps1 p1 psp stats s s1 logs l l100 l300 l500 x sh bash down d start stop restart build b pull default info help h"
        COMPREPLY=($(compgen -W "${commands}" -- ${cur}))
    elif [[ "$cur" == -* ]]; then
        # Autocomplete flags for commands that support them
        case "$command" in
            up|u|ul|down|d|build|b)
                local flags="-p -l -f --force"
                # Get already used flags to avoid duplicates
                local used_flags=""
                for ((i=1; i<COMP_CWORD; i++)); do
                    if [[ "${COMP_WORDS[i]}" == -* ]]; then
                        used_flags+="${COMP_WORDS[i]} "
                    fi
                done

                # Filter already used flags
                local available_flags=""
                for flag in $flags; do
                    if [[ ! "$used_flags" =~ $flag ]]; then
                        available_flags+="$flag "
                    fi
                done

                COMPREPLY=($(compgen -W "${available_flags}" -- ${cur}))
                ;;
        esac
    else
        # Autocomplete services after commands and flags
        case "$command" in
            x|sh|bash|logs|l|l100|l300|l500|start|stop|restart|up|u|ul|down|d|build|b)
                # Only complete services if we're not completing a flag
                if [[ "$prev" != -* ]] || [[ "$has_flags" == true ]]; then
                    local services=$(_get_compose_services)
                    COMPREPLY=($(compgen -W "${services}" -- ${cur}))
                fi
                ;;
            default)
                # For default command, complete with files and special subcommands
                if [[ ${COMP_CWORD} == 2 ]]; then
                    # First argument after 'default' - show files and subcommands
                    local files=$(ls *.yml *.yaml 2>/dev/null)
                    local subcommands="remove rm"
                    COMPREPLY=($(compgen -W "${files} ${subcommands}" -- ${cur}))
                fi
                ;;
        esac
    fi
}

# Autocompletion for quick functions
_dq_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local containers=$(_get_docker_containers)
    COMPREPLY=($(compgen -W "${containers}" -- ${cur}))
}

_dcq_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local services=$(_get_compose_services)
    COMPREPLY=($(compgen -W "${services}" -- ${cur}))
}

_dcdown_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local services=$(_get_compose_services)
    COMPREPLY=($(compgen -W "${services}" -- ${cur}))
}

_dcl_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local services=$(_get_compose_services)
    COMPREPLY=($(compgen -W "${services}" -- ${cur}))
}

_dcx_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local services=$(_get_compose_services)
    COMPREPLY=($(compgen -W "${services}" -- ${cur}))
}

_dx_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local containers=$(_get_docker_containers)
    COMPREPLY=($(compgen -W "${containers}" -- ${cur}))
}

_dl_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local containers=$(_get_docker_containers)
    COMPREPLY=($(compgen -W "${containers}" -- ${cur}))
}

# Specific autocompletion for dcup (same as dc up)
_dcup_completion() {
    local cur prev has_flags
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    has_flags=false

    # Check if there are already flags in the command line
    for ((i=1; i<COMP_CWORD; i++)); do
        if [[ "${COMP_WORDS[i]}" == -* ]]; then
            has_flags=true
            break
        fi
    done

    if [[ "$cur" == -* ]]; then
        # Autocomplete flags for up
        local flags="-p -l -f -b"
        local used_flags=""
        for ((i=1; i<COMP_CWORD; i++)); do
            if [[ "${COMP_WORDS[i]}" == -* ]]; then
                used_flags+="${COMP_WORDS[i]} "
            fi
        done
        local available_flags=""
        for flag in $flags; do
            if [[ ! "$used_flags" =~ $flag ]]; then
                available_flags+="$flag "
            fi
        done
        COMPREPLY=( $(compgen -W "$available_flags" -- "$cur") )
    else
        # Autocomplete services after flags
        local services=$(_get_compose_services)
        COMPREPLY=( $(compgen -W "$services" -- "$cur") )
    fi
}

# Register autocompletions for main functions
complete -F _d_completion d
complete -F _dc_completion dc
complete -F _dq_completion dq
complete -F _dcq_completion dcq

# Register autocompletions for specific aliases
complete -F _dcup_completion dcup
complete -F _dcdown_completion dcdown
complete -F _dcl_completion dcl
complete -F _dcx_completion dcx
complete -F _dx_completion dx
complete -F _dl_completion dl

# ==============================================================
# Help Functions
# ==============================================================

_docker_help() {
    cat << 'EOF'
🐳 Docker Helper (d)

BASIC:
  d ps, d p          - List containers
  d ps1, d p1        - List compact format
  d psp              - List with ports
  d images, d i      - List images

LOGS & STATS:
  d logs, d l        - Real-time logs
  d l100/l300/l500   - Logs with tail
  d stats, d s       - Real-time stats
  d s1               - Stats once

EXEC:
  d x CONTAINER CMD  - Execute command
  d sh CONTAINER     - Shell sh
  d bash CONTAINER   - Shell bash

CONTROL:
  d start/stop/restart CONTAINER
  d rm/rmi           - Remove container/image
  d kill             - Kill container

CLEANUP:
  d prune            - Clean system
  d prunea           - Clean all (aggressive)

QUICK:
  dq PATTERN CMD     - Execute in first matching container
  dstatus            - Quick status
  dcleanup           - Complete cleanup

Examples:
  d x web bash       - Bash in 'web' container
  dq nginx ls        - ls in first container containing 'nginx'
EOF
}

_compose_help() {
    cat << 'EOF'
🐙 Docker Compose Helper (dc)

BASIC:
  dc up, dc u          - Start services
  dc up -p            - Up with pull
  dc up -f FILE       - Up using specific compose file
  dc up --force       - Up forcing recreation
  dc up -b            - Up with build
  dc ul               - Up + automatic logs
  dc down, dc d        - Stop services
  dc down -f FILE     - Down using specific compose file

STATUS:
  dc ps, dc p          - List services
  dc ps1, dc p1        - List compact format
  dc psp              - List with ports
  dc info             - Show compose configuration

LOGS & STATS:
  dc logs, dc l        - Real-time logs
  dc l100/l300/l500   - Logs with tail
  dc stats, dc s       - Real-time stats

EXEC:
  dc x SERVICE CMD    - Execute command
  dc sh SERVICE       - Shell sh
  dc bash SERVICE     - Shell bash

CONTROL:
  dc start/stop/restart SERVICE
  dc build, dc b       - Build services
  dc build -f FILE    - Build using specific compose file
  dc pull             - Pull images

FILE MANAGEMENT:
  dc default FILE     - Set default compose file
  dc default          - Show current default
  dc default remove   - Remove default setting

QUICK:
  dcq PATTERN CMD    - Execute in first matching service

Examples:
  dc x api bash      - Bash in 'api' service
  dc ul web          - Up web service + logs
  dc up --force -l   - Up forcing recreation + logs
  dc up -pl          - Up with pull + logs
  dc up -f prod.yml  - Up using prod.yml compose file
  dc default app.yml - Set app.yml as default compose file
  dcq data psql      - psql in first service containing 'data'
EOF
}

# ==============================================================
# Help aliases
# ==============================================================
alias dhelp='_docker_help'
alias dchelp='_compose_help'
alias dockerhelp='echo "Use: dhelp (docker) or dchelp (compose)"'

# ==============================================================
# Intelligent logs with search and confirmation
# ==============================================================
dclt() {
    local regex_mode=false
    local ask_confirm=false
    local patterns=()
    local services
    local matched_services=()
    local arg

    # Check for compose file first
    local compose_file=$(_get_compose_file)
    if [[ $? -ne 0 ]]; then
        echo -e "${CRE}No compose file found. Expected ${CB}docker-compose.yml${CR}, ${CB}docker-compose.yaml${CR}, or set ${CB}DOCKER_COMPOSE_FILE${CR} environment variable ❌${CR}"
        return 1
    fi

    # Parse combined flags and arguments
    while [[ $# -gt 0 ]]; do
        if [[ "$1" == --* ]]; then
            case "$1" in
                --regex)
                    regex_mode=true
                    ;;
                --wait)
                    ask_confirm=true
                    ;;
                *)
                    echo "❌ Unrecognized option: $1" >&2
                    return 1
                    ;;
            esac
        elif [[ "$1" == -* && "$1" != "-" ]]; then
            local flags="${1#-}"
            for ((i=0; i<${#flags}; i++)); do
                case "${flags:$i:1}" in
                    r) regex_mode=true ;;
                    w) ask_confirm=true ;;
                    *)
                        echo "❌ Unrecognized option: -${flags:$i:1}" >&2
                        return 1
                        ;;
                esac
            done
        else
            patterns+=("$1")
        fi
        shift
    done

    # Get services list
    services=($(_get_compose_services))
    if [[ ${#services[@]} -eq 0 ]]; then
        echo -e "${CRE}No compose services found ❌"
        return 1
    fi

    # Search for matches
    if [[ ${#patterns[@]} -gt 0 ]]; then
        if [[ "$regex_mode" == true ]]; then
            for svc in "${services[@]}"; do
                for pat in "${patterns[@]}"; do
                    if [[ "$svc" =~ $pat ]]; then
                        matched_services+=("$svc")
                        break
                    fi
                done
            done
        else
            for pat in "${patterns[@]}"; do
                for svc in "${services[@]}"; do
                    if [[ "$svc" == "$pat" ]]; then
                        matched_services+=("$svc")
                    fi
                done
            done
        fi
    else
        matched_services=("${services[@]}")
    fi

    # Remove duplicates (compatible with bash and zsh)
    local unique_services=()
    for svc in "${matched_services[@]}"; do
        local found=false
        for usvc in "${unique_services[@]}"; do
            if [[ "$svc" == "$usvc" ]]; then
                found=true
                break
            fi
        done
        if [[ "$found" == false ]]; then
            unique_services+=("$svc")
        fi
    done

    if [[ ${#unique_services[@]} -eq 0 ]]; then
        echo -e "${CRE}No services found matching: ${CB}'${patterns[*]}'${CR} ❌"
        return 1
    fi

    echo -e "${CGR}Services found: ${CB}${unique_services[*]}${CR} 📋"
    if [[ "$ask_confirm" == true ]]; then
        if ! _confirm_operation "Show logs for these services?"; then
            return 0
        fi
    fi
    docker compose -f "$compose_file" logs --tail 100 -f "${unique_services[@]}"
}

# ==============================================================
# Autocompletion for dclt (bash and zsh)
# ==============================================================
_dclt_completion() {
    local cur prev opts services
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="-r --regex -w --wait"
    services=$(_get_compose_services)

    # Complete flags
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$opts" -- "$cur"))
        return 0
    fi
    # Complete services
    COMPREPLY=($(compgen -W "$services" -- "$cur"))
}

complete -F _dclt_completion dclt

# ==============================================================
# Show git.properties from a compose container
# ==============================================================
dcpr() {
    local show_all=false show_summary=false
    local services=() service

    # Check for compose file first
    local compose_file=$(_get_compose_file)
    if [[ $? -ne 0 ]]; then
        echo -e "${CRE}No compose file found. Expected ${CB}docker-compose.yml${CR}, ${CB}docker-compose.yaml${CR}, or set ${CB}DOCKER_COMPOSE_FILE${CR} environment variable ❌${CR}"
        return 1
    fi

    # Parse flags and arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -a)
                show_all=true
                ;;
            -s)
                show_summary=true
                ;;
            -as|-sa)
                show_all=true; show_summary=true
                ;;
            --all)
                show_all=true
                ;;
            --summary)
                show_summary=true
                ;;
            --)
                shift; break
                ;;
            -*)
                echo "❌ Unrecognized option: $1" >&2
                return 1
                ;;
            *)
                services+=("$1")
                ;;
        esac
        shift
    done

    if [[ "$show_all" == true ]]; then
        local all_services=($(_get_compose_services))
        if [[ ${#all_services[@]} -eq 0 ]]; then
            echo "❌ No compose services found."
            return 1
        fi
        if [[ "$show_summary" == true ]]; then
            printf "Processing services...\n" >&2
            # 1. Collect rows and calculate maximum widths
            local -a rows
            local max_service=12 max_commit=9 max_email=9 max_branch=6 max_msg=13
            for svc in "${all_services[@]}"; do
                printf "Processing: %s\r" "$svc" >&2
                local props=$(docker compose -f "$compose_file" exec "$svc" sh -c 'if [ -f /app/resources/git.properties ]; then cat /app/resources/git.properties; elif [ -f /usr/share/nginx/html/git.properties ]; then cat /usr/share/nginx/html/git.properties; fi' 2>/dev/null)
                if [[ -z "$props" ]]; then
                    continue
                fi
                local branch commit_id user_email commit_msg
                commit_id=$(echo "$props" | grep -E '^git\.commit.id=' | head -1 | cut -d= -f2-)
                user_email=$(echo "$props" | grep -E '^git\.commit.user.email=' | head -1 | cut -d= -f2-)
                branch=$(echo "$props" | grep -E '^git\.branch=' | head -1 | cut -d= -f2-)
                commit_msg=$(echo "$props" | grep -E '^git\.commit.message.full=' | head -1 | cut -d= -f2-)
                if [[ -z "$commit_msg" ]]; then
                    commit_msg=$(echo "$props" | grep -E '^git\.commit.message.short=' | head -1 | cut -d= -f2-)
                fi
                commit_msg=$(echo "$commit_msg" | tr '\n' ' ' | tr -s ' ')
                # Save row and calculate widths
                rows+=("$svc|$commit_id|$user_email|$branch|$commit_msg")
                (( ${#svc} > max_service )) && max_service=${#svc}
                (( ${#commit_id} > max_commit )) && max_commit=${#commit_id}
                (( ${#user_email} > max_email )) && max_email=${#user_email}
                (( ${#branch} > max_branch )) && max_branch=${#branch}
                (( ${#commit_msg} > max_msg )) && max_msg=${#commit_msg}
            done
            # Limit maximum width of commit_msg
            (( max_msg > 60 )) && max_msg=60
            # 2. Print header with lines above and below
            local total_width=$((max_service+max_commit+max_email+max_branch+max_msg+13))
            printf -- '%*s\n' "$total_width" '' | tr ' ' '-'
            printf "%-${max_service}s | %- ${max_commit}s | %- ${max_email}s | %- ${max_branch}s | %- ${max_msg}s\n" "SERVICE_NAME" "COMMIT_ID" "USER_EMAIL" "BRANCH" "COMMIT_MESSAGE"
            printf -- '%*s\n' "$total_width" '' | tr ' ' '-'
            # 3. Print rows
            for row in "${rows[@]}"; do
                IFS='|' read -r svc commit_id user_email branch commit_msg <<< "$row"
                # Truncate commit_msg if necessary
                [[ ${#commit_msg} -gt $max_msg ]] && commit_msg="${commit_msg:0:max_msg}"
                printf "%-${max_service}s | %- ${max_commit}s | %- ${max_email}s | %- ${max_branch}s | %- ${max_msg}s\n" "$svc" "$commit_id" "$user_email" "$branch" "$commit_msg"
            done
            printf "\n" >&2
        else
            # Show all complete git.properties
            for svc in "${all_services[@]}"; do
                echo "# $svc"
                docker compose -f "$compose_file" exec "$svc" sh -c 'if [ -f /app/resources/git.properties ]; then cat /app/resources/git.properties; elif [ -f /usr/share/nginx/html/git.properties ]; then cat /usr/share/nginx/html/git.properties; else echo "❌ git.properties not found"; fi'
                echo
            done
        fi
        return 0
    fi

    # Simple case: single service
    if [[ ${#services[@]} -eq 0 ]]; then
        echo "Usage: dcpr <service> | dcpr -a | dcpr -a -s"
        return 1
    fi
    service="${services[0]}"
    docker compose -f "$compose_file" exec "$service" sh -c 'if [ -f /app/resources/git.properties ]; then cat /app/resources/git.properties; elif [ -f /usr/share/nginx/html/git.properties ]; then cat /usr/share/nginx/html/git.properties; else echo "❌ git.properties not found"; fi'
}

# Autocompletion for dcpr (compose services)
_dcpr_completion() {
    local cur services
    cur="${COMP_WORDS[COMP_CWORD]}"
    services=$(_get_compose_services)
    COMPREPLY=( $(compgen -W "$services" -- "$cur") )
}

complete -F _dcpr_completion dcpr
