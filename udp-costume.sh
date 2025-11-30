#!/bin/bash

# ==================================================
# UDP CUSTOM - MAIN SCRIPT
# ==================================================

# Load libraries
source /etc/udp-custom/lib/colors.sh
source /etc/udp-custom/lib/banners.sh
source /etc/udp-custom/lib/helpers.sh

# Load modules
source /etc/udp-custom/modules/utilities.sh
source /etc/udp-custom/modules/ssh.sh
source /etc/udp-custom/modules/vmess.sh
source /etc/udp-custom/modules/vless.sh
source /etc/udp-custom/modules/trojan.sh
source /etc/udp-custom/modules/nginx.sh
source /etc/udp-custom/modules/ssl.sh
source /etc/udp-custom/modules/backup.sh
source /etc/udp-custom/modules/bandwidth.sh

# Config file
CONFIG_FILE="/etc/udp-custom/config/config.json"

# Initialize
initialize() {
    check_root
    load_config
    check_dependencies
}

# Main menu
main_menu() {
    while true; do
        clear
        print_main_banner
        
        echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║           ${CYAN}MAIN MENU${GREEN}                   ║${NC}"
        echo -e "${GREEN}╠════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║   ${WHITE}1. SSH WS UDP Manager${NC}                ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}2. Vmess Manager${NC}                     ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}3. Vless Manager${NC}                     ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}4. Trojan Manager${NC}                    ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}5. Fix Nginx Configuration${NC}           ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}6. Fix & Install SSL${NC}                 ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}7. Pointing Domain SSL${NC}               ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}8. Auto Backup Manager${NC}               ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}9. Monitor Bandwidth Aktif${NC}           ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}10. Batasi Kecepatan Per Akun${NC}        ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}11. Batasi Kecepatan Server${NC}          ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}12. User Management${NC}                  ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}13. System Info${NC}                      ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${RED}0. Exit${NC}                            ${GREEN}║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
        echo ""
        
        read -p "Pilih menu [0-13]: " choice
        
        case $choice in
            1) manage_ssh_menu ;;
            2) manage_vmess_menu ;;
            3) manage_vless_menu ;;
            4) manage_trojan_menu ;;
            5) fix_nginx_menu ;;
            6) fix_ssl_menu ;;
            7) pointing_domain_menu ;;
            8) backup_menu ;;
            9) monitor_bandwidth_menu ;;
            10) limit_account_bandwidth_menu ;;
            11) limit_server_bandwidth_menu ;;
            12) user_management_menu ;;
            13) system_info_menu ;;
            0) 
                echo -e "${GREEN}Terima kasih telah menggunakan UDP Custom!${NC}"
                exit 0 
                ;;
            *) 
                echo -e "${RED}Pilihan tidak valid!${NC}"
                sleep 2
                ;;
        esac
    done
}

# Start script
initialize
main_menu