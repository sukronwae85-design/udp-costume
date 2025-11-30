#!/bin/bash

print_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
    _    _  ____  _____    _______ ______ _      
   | |  | |/ __ \|  __ \  |__   __|  ____| |     
   | |  | | |  | | |  | |    | |  | |__  | |     
   | |  | | |  | | |  | |    | |  |  __| | |     
   | |__| | |__| | |__| |    | |  | |____| |____ 
    \____/ \____/|_____/     |_|  |______|______|
                                                 
           UDP CUSTOM SCRIPT - PREMIUM
         Support All Ubuntu OS & Debian
EOF
    echo -e "${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${WHITE}    Timezone: $(date)${NC}"
    echo -e "${WHITE}    OS: $(uname -o) $(uname -m)${NC}"
    echo -e "${WHITE}    Hostname: $(hostname)${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
}

show_main_menu() {
    print_banner
    echo -e "${YELLOW}🎯 MAIN MENU - UDP CUSTOM SCRIPT${NC}"
    echo -e "${GREEN}1. ${WHITE}SSH WS UDP Manager${NC}"
    echo -e "${GREEN}2. ${WHITE}Vmess Manager${NC}"
    echo -e "${GREEN}3. ${WHITE}Trojan Manager${NC}"
    echo -e "${GREEN}4. ${WHITE}Fix Nginx Configuration${NC}"
    echo -e "${GREEN}5. ${WHITE}Fix & Install SSL${NC}"
    echo -e "${GREEN}6. ${WHITE}Pointing Domain SSL${NC}"
    echo -e "${GREEN}7. ${WHITE}Auto Backup (Gmail, WA, Telegram)${NC}"
    echo -e "${GREEN}8. ${WHITE}Monitor Bandwidth Aktif${NC}"
    echo -e "${GREEN}9. ${WHITE}Batasi Kecepatan Per Akun${NC}"
    echo -e "${GREEN}10. ${WHITE}Batasi Kecepatan Server${NC}"
    echo -e "${RED}0. ${WHITE}Exit${NC}"
    echo -e "${GREEN}=========================================${NC}"
}