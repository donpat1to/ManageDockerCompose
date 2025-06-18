#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Box-drawing characters (UTF-8)
HLINE="\u2500"
VLINE="\u2502"
CORNER_TL="\u250C"
CORNER_TR="\u2510"
CORNER_BL="\u2514"
CORNER_BR="\u2518"

# Cursor control sequences
SAVE_CURSOR=$'\e7'      # Save cursor pos (alternate, compatible)
RESTORE_CURSOR=$'\e8'   # Restore cursor pos
CLEAR_LINE=$'\e[2K'     # Clear entire line
MOVE_UP=$'\e[1A'        # Move cursor up 1 line
MOVE_START=$'\r'        # Move cursor to start of line

# Menu state
MENU_START_LINE=0

check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}Root privileges required. Please enter your password:${NC}"
        sudo "$0" "$@"
        exit $?
    fi
}

print_header() {
    local title_length=${#1}
    local line=$(printf "%0.s${HLINE}" $(seq 1 $((title_length + 2))))
    echo -e "${CYAN}${CORNER_TL}${line}${CORNER_TR}${NC}"
    echo -e "${CYAN}${VLINE} ${BLUE}${1}${NC} ${CYAN}${VLINE}${NC}"
    echo -e "${CYAN}${CORNER_BL}${line}${CORNER_BR}${NC}"
}

draw_menu() {
    if [ "$MENU_START_LINE" -eq 0 ]; then
        get_cursor_pos
        MENU_START_LINE=$CURSOR_LINE
    else
        move_cursor_to_line $MENU_START_LINE
        echo -ne "\033[J"  # Clear from cursor down to end of screen
    fi

    MENU_LINES=0

    print_header "$1"
    MENU_LINES=$((MENU_LINES + 3))

    shift
    for item in "$@"; do
        echo -e "$item"
        MENU_LINES=$((MENU_LINES + 1))
    done
    echo
    MENU_LINES=$((MENU_LINES + 1))
}

show_error() {
    echo -e "${RED}Error: $1${NC}"
    sleep 1
}

get_cursor_pos() {
    # Query terminal for cursor position
    # Returns line number (1-based) in CURSOR_LINE
    IFS=';' read -sdR -p $'\033[6n' ROW COL
    CURSOR_LINE=${ROW#*[}
}

move_cursor_to_line() {
    local line=$1
    echo -ne "\033[${line};0H"
}

main_menu() {
    while true; do
        draw_menu "Docker Service Manager" \
            "${GREEN}1)${NC} Stop Docker Compose" \
            "${GREEN}2)${NC} Restart Docker Compose" \
            "${GREEN}3)${NC} Update Server" \
            "${RED}0)${NC} Exit"

        echo -ne "${YELLOW}➤ Your choice: ${NC}"
        read -r opt

        case "$opt" in
            1) stop_menu ;;
            2) restart_menu ;;
            3) sudo ./scripts/update_server.sh ;;
            0) echo -e "\n${GREEN}Goodbye!${NC}"; exit 0 ;;
            *) show_error "Invalid selection" ;;
        esac
    done
}

stop_menu() {
    while true; do
        draw_menu "Stop Docker Compose" \
            "${GREEN}1)${NC} Stop all" \
            "${GREEN}2)${NC} Stop selected" \
            "${YELLOW}3)${NC} Back"

        echo -ne "${YELLOW}➤ Your choice: ${NC}"
        read -r subopt

        case "$subopt" in
            1) sudo ./scripts/shutdown_docker_services.sh all; break ;;
            2) select_services "stop"; break ;;
            3) break ;;
            *) show_error "Invalid selection" ;;
        esac
    done
}

restart_menu() {
    while true; do
        draw_menu "Restart Docker Compose" \
            "${GREEN}1)${NC} Restart all" \
            "${GREEN}2)${NC} Restart selected" \
            "${YELLOW}3)${NC} Back"

        echo -ne "${YELLOW}➤ Your choice: ${NC}"
        read -r subopt

        case "$subopt" in
            1)
                echo -ne "${YELLOW}Update compose files first? (y/n): ${NC}"
                read -r update
                [[ "$update" =~ ^[Yy] ]] && sudo ./scripts/update_docker_services.sh all
                sudo ./scripts/restart_docker_services.sh all
                break
                ;;
            2) select_services "restart"; break ;;
            3) break ;;
            *) show_error "Invalid selection" ;;
        esac
    done
}

select_services() {
    local action=$1
    local dirs=() options=()
    local index=1

    for dir in /srv/*/docker-compose.yaml; do
        [ -e "$dir" ] || continue
        local dirname=$(dirname "$dir")
        dirs+=("$dirname")
        options+=("${GREEN}$index)${NC} $(basename "$dirname")")
        ((index++))
    done

    while true; do
        draw_menu "Select services to $action" "${options[@]}" "${YELLOW}$index)${NC} Back"

        echo -ne "${YELLOW}➤ Enter numbers (e.g. 123): ${NC}"
        read -r selection

        if [[ "$selection" == "$index" ]]; then
            return 1
        fi

        local selected=()
        for ((i=0; i<${#selection}; i++)); do
            local digit=${selection:$i:1}
            if [[ "$digit" =~ ^[0-9]$ ]] && [ "$digit" -gt 0 ] && [ "$digit" -lt "$index" ]; then
                selected+=("${dirs[$((digit-1))]}")
            fi
        done

        if [ ${#selected[@]} -gt 0 ]; then
            case "$action" in
                "stop")
                    sudo ./scripts/shutdown_docker_services.sh "${selected[@]}"
                    return 0
                    ;;
                "restart")
                    echo -ne "${YELLOW}Update compose files first? (y/n): ${NC}"
                    read -r update
                    [[ "$update" =~ ^[Yy] ]] && sudo ./scripts/update_docker_services.sh "${selected[@]}"
                    sudo ./scripts/restart_docker_services.sh "${selected[@]}"
                    return 0
                    ;;
            esac
        else
            show_error "No valid services selected"
        fi
    done
}

cleanup() {
    # Reset terminal colors and cursor
    echo -ne "${NC}"
    echo -ne "\033[?25h"  # Show cursor if hidden
    echo  # Move to new line to avoid prompt on menu line
    exit 130  # 130 = script terminated by Ctrl+C
}

trap cleanup SIGINT

check_sudo "$@"
main_menu
