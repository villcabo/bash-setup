#!/usr/bin/env bash

# ==============================================================
# Docker Aliases - Enhanced and Simplified Version
# ==============================================================

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
    case "$1" in
        # Up with smart options
        up|u)
            shift
            local opts=""
            local show_logs=false
            local services=()

            # Parse flags and services
            while [[ $# -gt 0 ]]; do
                if [[ $1 == -* ]]; then
                    local flags="${1#-}"
                    for ((i=0; i<${#flags}; i++)); do
                        case "${flags:$i:1}" in
                            p) opts+=" --pull always" ;;
                            f) opts+=" --force-recreate" ;;
                            b) opts+=" --build" ;;
                            l) show_logs=true ;;
                        esac
                    done
                else
                    services+=("$1")
                fi
                shift
            done

            # Get available services
            local all_services=($(_get_compose_services))
            local target_services=()

            if [[ ${#services[@]} -eq 0 ]]; then
                target_services=("${all_services[@]}")
            else
                target_services=("${services[@]}")
            fi

            # Show confirmation with colors
            echo -e "\033[1;33m╔══════════════════════════════════════════════════════════════╗\033[0m"
            echo -e "\033[1;33m║                    DOCKER COMPOSE UP                         ║\033[0m"
            echo -e "\033[1;33m╚══════════════════════════════════════════════════════════════╝\033[0m"
            echo -e "\033[1;36mAction:\033[0m Start Docker Compose services"
            if [[ -n "$opts" ]]; then
                echo -e "\033[1;36mOptions:\033[0m$opts"
            fi
            echo -e "\033[1;36mAffected services:\033[0m \033[1;32m${target_services[*]}\033[0m"
            if [[ "$show_logs" == true ]]; then
                echo -e "\033[1;36mAdditional action:\033[0m Show logs after up"
            fi
            echo ""
            printf "\033[1;31mContinue with operation? [yes/N]: \033[0m"
            read -r response

            if [[ "$response" == "yes" ]]; then
                local cmd="docker compose up -d$opts"
                if [[ ${#services[@]} -gt 0 ]]; then
                    cmd+=" ${services[*]}"
                fi

                if eval "$cmd"; then
                    if [[ "$show_logs" == true ]]; then
                        if [[ ${#services[@]} -gt 0 ]]; then
                            docker compose logs -f "${services[@]}"
                        else
                            docker compose logs -f
                        fi
                    fi
                fi
            else
                echo -e "\033[1;33mOperation cancelled.\033[0m"
                return 1
            fi
            ;;

        # Up con logs automáticos
        ul)       shift; docker compose up -d "$@" && docker compose logs -f "$@" ;;

        # Básicos
        ps|p)     shift; docker compose ps "$@" | docker-color-output ;;
        ps1|p1)   shift; docker compose ps --format "table {{.Name}}\\t{{.Service}}\\t{{.RunningFor}}\\t{{.Status}}\\t{{.Image}}" "$@" | docker-color-output ;;
        psp)      shift; docker compose ps --format "table {{.Name}}\\t{{.Service}}\\t{{.Ports}}" "$@" | docker-color-output ;;

        # Stats y logs
        stats|s)  shift; docker compose stats "$@" | docker-color-output ;;
        s1)       shift; docker compose stats --no-stream "$@" | docker-color-output ;;
        logs|l)   shift; docker compose logs --tail 100 -f "$@" ;;
        l100)     shift; docker compose logs --tail 100 -f "$@" ;;
        l300)     shift; docker compose logs --tail 300 -f "$@" ;;
        l500)     shift; docker compose logs --tail 500 -f "$@" ;;

        # Exec (más simple)
        x)        shift; docker compose exec "$@" ;;
        sh)       shift; docker compose exec "$1" sh ;;
        bash)     shift; docker compose exec "$1" bash ;;

        # Control de servicios
        down|d)   shift; docker compose down "$@" ;;
        start)    shift; docker compose start "$@" ;;
        stop)     shift; docker compose stop "$@" ;;
        restart)  shift; docker compose restart "$@" ;;

        # Build y pull
        build|b)  shift; docker compose build "$@" ;;
        pull)     shift; docker compose pull "$@" ;;

        # Ayuda
        help|h)   _compose_help ;;

        # Por defecto, pasar comando directo a docker compose
        *)        docker compose "$@" ;;
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
    # Get available services
    local all_services=($(_get_compose_services))
    local target_services=()

    # Parse arguments to get specific services
    local services=()
    local opts=""
    local show_logs=false

    for arg in "$@"; do
        if [[ $arg == -* ]]; then
            local flags="${arg#-}"
            for ((i=0; i<${#flags}; i++)); do
                case "${flags:$i:1}" in
                    p) opts+=" --pull always" ;;
                    f) opts+=" --force-recreate" ;;
                    b) opts+=" --build" ;;
                    l) show_logs=true ;;
                esac
            done
        else
            services+=("$arg")
        fi
    done

    if [[ ${#services[@]} -eq 0 ]]; then
        target_services=("${all_services[@]}")
    else
        target_services=("${services[@]}")
    fi

    # Show confirmation with colors
    echo -e "\033[1;33m╔══════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;33m║                    DOCKER COMPOSE UP                         ║\033[0m"
    echo -e "\033[1;33m╚══════════════════════════════════════════════════════════════╝\033[0m"
    echo -e "\033[1;36mAction:\033[0m Start Docker Compose services"
    if [[ -n "$opts" ]]; then
        echo -e "\033[1;36mOptions:\033[0m$opts"
    fi
    echo -e "\033[1;36mAffected services:\033[0m \033[1;32m${target_services[*]}\033[0m"
    if [[ "$show_logs" == true ]]; then
        echo -e "\033[1;36mAdditional action:\033[0m Show logs after up"
    fi
    echo ""
    printf "\033[1;31mContinue with operation? [yes/N]: \033[0m"
    read -r response

    if [[ "$response" == "yes" ]]; then
        local cmd="docker compose up -d$opts"
        if [[ ${#services[@]} -gt 0 ]]; then
            cmd+=" ${services[*]}"
        fi

        if eval "$cmd"; then
            if [[ "$show_logs" == true ]]; then
                if [[ ${#services[@]} -gt 0 ]]; then
                    docker compose logs -f "${services[@]}"
                else
                    docker compose logs -f
                fi
            fi
        fi
    else
        echo -e "\033[1;33mOperation cancelled.\033[0m"
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
        echo "→ Executing in: $container"
        shift
        docker exec -it "$container" "$@"
    else
        echo "❌ No container found matching: $1"
        return 1
    fi
}

# Function to execute command in the first service that matches
dcq() {
    if [[ ! -f docker-compose.yml ]] && [[ ! -f docker-compose.yaml ]] && [[ ! -f compose.yml ]] && [[ ! -f compose.yaml ]]; then
        echo "❌ No compose file in this directory"
        return 1
    fi

    local service=$(docker compose ps --services | grep -i "$1" | head -1)
    if [[ -n "$service" ]]; then
        echo "→ Executing in service: $service"
        shift
        docker compose exec "$service" "$@"
    else
        echo "❌ No service found matching: $1"
        return 1
    fi
}

# Function to show quick status
dstatus() {
    echo "=== CONTAINERS ==="
    docker ps --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}" | docker-color-output

    if [[ -f docker-compose.yml ]] || [[ -f docker-compose.yaml ]] || [[ -f compose.yml ]] || [[ -f compose.yaml ]]; then
        echo -e "\n=== COMPOSE SERVICES ==="
        docker compose ps --format "table {{.Service}}\\t{{.Status}}\\t{{.Ports}}" | docker-color-output
    fi
}

# Function to clean everything at once
dcleanup() {
    echo "🧹 Cleaning Docker..."
    docker system prune -f
    docker network prune -f
    echo "✅ Cleanup completed"
}

# ==============================================================
# Enhanced Autocompletion
# ==============================================================

_get_docker_containers() {
    docker ps --format "{{.Names}}" 2>/dev/null
}

_get_compose_services() {
    # Priority: docker-compose.yml > docker-compose.yaml > compose.yml > compose.yaml
    if [[ -f docker-compose.yml ]]; then
        docker compose config --services 2>/dev/null
    elif [[ -f docker-compose.yaml ]]; then
        docker compose -f docker-compose.yaml config --services 2>/dev/null
    elif [[ -f compose.yml ]]; then
        docker compose -f compose.yml config --services 2>/dev/null
    elif [[ -f compose.yaml ]]; then
        docker compose -f compose.yaml config --services 2>/dev/null
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
        local commands="up u ul ps p ps1 p1 psp stats s s1 logs l l100 l300 l500 x sh bash down d start stop restart build b pull help h"
        COMPREPLY=($(compgen -W "${commands}" -- ${cur}))
    elif [[ "$cur" == -* ]]; then
        # Autocomplete flags for commands that support them
        case "$command" in
            up|u|ul)
                local flags="-p -l -f -b"
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
  dc up -f            - Up forcing recreation
  dc up -b            - Up with build
  dc ul               - Up + automatic logs
  dc down, dc d        - Stop services

STATUS:
  dc ps, dc p          - List services
  dc ps1, dc p1        - List compact format
  dc psp              - List with ports

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
  dc pull             - Pull images

QUICK:
  dcq PATTERN CMD    - Execute in first matching service

Examples:
  dc x api bash      - Bash in 'api' service
  dc ul web          - Up web service + logs
  dc up -fl          - Up forcing recreation + logs
  dc up -pl          - Up with pull + logs
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
        echo "❌ No compose services found."
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
        echo "❌ No services found matching '${patterns[*]}'"
        return 1
    fi

    echo "Services found: ${unique_services[*]}"
    if [[ "$ask_confirm" == true ]]; then
        printf "Show logs for these services? [yes/N]: "
        read resp
        if [[ "$resp" == "yes" ]]; then
            : # continue
        else
            return 0
        fi
    fi
    docker compose logs --tail 100 -f "${unique_services[@]}"
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
                local props=$(docker compose exec "$svc" sh -c 'if [ -f /app/resources/git.properties ]; then cat /app/resources/git.properties; elif [ -f /usr/share/nginx/html/git.properties ]; then cat /usr/share/nginx/html/git.properties; fi' 2>/dev/null)
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
                docker compose exec "$svc" sh -c 'if [ -f /app/resources/git.properties ]; then cat /app/resources/git.properties; elif [ -f /usr/share/nginx/html/git.properties ]; then cat /usr/share/nginx/html/git.properties; else echo "❌ git.properties not found"; fi'
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
    docker compose exec "$service" sh -c 'if [ -f /app/resources/git.properties ]; then cat /app/resources/git.properties; elif [ -f /usr/share/nginx/html/git.properties ]; then cat /usr/share/nginx/html/git.properties; else echo "❌ git.properties not found"; fi'
}

# Autocompletion for dcpr (compose services)
_dcpr_completion() {
    local cur services
    cur="${COMP_WORDS[COMP_CWORD]}"
    services=$(_get_compose_services)
    COMPREPLY=( $(compgen -W "$services" -- "$cur") )
}

complete -F _dcpr_completion dcpr
