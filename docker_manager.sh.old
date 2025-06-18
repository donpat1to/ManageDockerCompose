#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Box-Drawing Characters
HLINE="\u2500"
VLINE="\u2502"
CORNER_TL="\u250C"
CORNER_TR="\u2510"
CORNER_BL="\u2514"
CORNER_BR="\u2518"

check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}Root privileges required. Please enter your password:${NC}"
        sudo "$0" "$@"
        exit $?
    fi
}

print_header() {
    #clear
    local title_length=${#1}
    local line=$(printf "%0.s${HLINE}" $(seq 1 $((title_length + 2))))
    echo -e "${CYAN}${CORNER_TL}${line}${CORNER_TR}${NC}"
    echo -e "${VLINE} ${BLUE}${1}${NC} ${VLINE}"
    echo -e "${CYAN}${CORNER_BL}${line}${CORNER_BR}${NC}"
    echo
}

list_compose_dirs() {
    COMPOSE_DIRS=()
    INDEX=1
    for dir in /srv/*/docker-compose.yaml; do
        [ -e "$dir" ] || continue
        parent=$(dirname "$dir")
        printf "${GREEN}%2d)${NC} %s\n" "$INDEX" "$(basename "$parent")"
        COMPOSE_DIRS+=("$parent")
        ((INDEX++))
    done
    echo
}

get_selection() {
    echo -ne "${YELLOW}➤ Enter the numbers (e.g. 123): ${NC}"
    read -r selection
    SELECTED_DIRS=()
    for ((i=0; i<${#selection}; i++)); do
        digit=${selection:$i:1}
        dir=${COMPOSE_DIRS[$((digit-1))]}
        [[ -d "$dir" ]] && SELECTED_DIRS+=("$dir")
    done
}

show_menu() {
    print_header "Docker Service Manager"

    echo -e "${GREEN}Main Menu:${NC}"
    echo -e "  ${CYAN}1)${NC} Stop Docker Compose"
    echo -e "  ${CYAN}2)${NC} Restart Docker Compose"
    echo -e "  ${CYAN}3)${NC} Update Server"
    echo -e "  ${RED}0)${NC} Exit"
    echo
}

show_submenu() {
    local title=$1
    local option1=$2
    local option2=$3

    print_header "$title"
    echo -e "${GREEN}Options:${NC}"
    echo -e "  ${CYAN}1)${NC} $option1"
    echo -e "  ${CYAN}2)${NC} $option2"
    echo -e "  ${YELLOW}3)${NC} Back to Main Menu"
    echo
}

main_menu() {
    while true; do
        show_menu
        read -rp "$(echo -ne "${YELLOW}➤ Your choice: ${NC}")" opt

        case "$opt" in
            1)
                while true; do
                    show_submenu "Stop Docker Compose" "Stop all" "Stop selected"
                    read -rp "$(echo -ne "${YELLOW}➤ Your choice: ${NC}")" subopt

                    case "$subopt" in
                        1)
                            sudo ./shutdown_docker_services.sh all
                            break 2
                            ;;
                        2)
                            print_header "Stop Selected Services"
                            list_compose_dirs
                            get_selection
                            if [ ${#SELECTED_DIRS[@]} -gt 0 ]; then
                                sudo ./shutdown_docker_services.sh "${SELECTED_DIRS[@]}"
                            else
                                echo -e "${RED}No valid selection made.${NC}"
                            fi
                            break 2
                            ;;
                        3)
                            break
                            ;;
                        *)
                            echo -e "${RED}Invalid selection${NC}"
                            ;;
                    esac
                done
                ;;
            2)
                while true; do
                    show_submenu "Restart Docker Compose" "Restart all" "Restart selected"
                    read -rp "$(echo -ne "${YELLOW}➤ Your choice: ${NC}")" subopt

                    case "$subopt" in
                        1|2)
                            read -rp "$(echo -ne "${YELLOW}➤ Update docker-compose first? (y/n): ${NC}")" update
                            
                            if [[ "$subopt" == "1" ]]; then
                                if [[ "$update" == [Yy]* ]]; then
                                    sudo ./update_docker_services.sh all
                                fi
                                sudo ./restart_docker_services.sh all
                            else
                                print_header "Restart Selected Services"
                                list_compose_dirs
                                get_selection
                                if [ ${#SELECTED_DIRS[@]} -gt 0 ]; then
                                    if [[ "$update" == [Yy]* ]]; then
                                        sudo ./update_docker_services.sh "${SELECTED_DIRS[@]}"
                                    fi
                                    sudo ./restart_docker_services.sh "${SELECTED_DIRS[@]}"
                                else
                                    echo -e "${RED}No valid selection made.${NC}"
                                fi
                            fi
                            break 2
                            ;;
                        3)
                            break
                            ;;
                        *)
                            echo -e "${RED}Invalid selection${NC}"
                            ;;
                    esac
                done
                ;;
            3)
                sudo ./update_server.sh
                ;;
            0)
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid selection${NC}"
                sleep 1
                ;;
        esac
    done
}

check_sudo "$@"
main_menu
