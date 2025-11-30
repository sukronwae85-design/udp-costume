#!/bin/bash

# ==================================================
# UDP CUSTOM SCRIPT - MAIN FILE
# Author: Sukron Wae
# GitHub: https://github.com/sukronwae85-design/udp-costume
# ==================================================

# Config
export DEBIAN_FRONTEND=noninteractive
TIMEZONE="Asia/Jakarta"
OS_CHECK=$(lsb_release -is 2>/dev/null || cat /etc/os-release | grep ^ID= | cut -d= -f2)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Load modules
source modules/utils.sh
source modules/menu.sh
source modules/ssh_manager.sh
source modules/vmess_manager.sh
source modules/vless_manager.sh
source modules/trojan_manager.sh
source modules/nginx_manager.sh
source modules/ssl_manager.sh
source modules/backup_manager.sh
source modules/bandwidth_manager.sh

# Initial setup
initial_setup() {
    clear
    print_banner
    check_root
    check_os
    update_system
    set_timezone
    install_dependencies
}

# Main function
main() {
    initial_setup
    
    while true; do
        show_main_menu
        read -p "Pilih menu [1-10]: " choice
        
        case $choice in
            1) manage_ssh ;;
            2) manage_vmess ;;
            3) manage_trojan ;;
            4) fix_nginx ;;
            5) fix_ssl ;;
            6) pointing_domain ;;
            7) auto_backup ;;
            8) monitor_bandwidth ;;
            9) limit_account_bandwidth ;;
            10) limit_server_bandwidth ;;
            *) echo -e "${RED}Pilihan tidak valid!${NC}" ;;
        esac
    done
}

# Run main function
main "$@"