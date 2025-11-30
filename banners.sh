#!/bin/bash

print_main_banner() {
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
    echo -e "${WHITE}    Author: Sukron Wae${NC}"
    echo -e "${WHITE}    GitHub: sukronwae85-design${NC}"
    echo -e "${WHITE}    Time: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${WHITE}    Timezone: Asia/Jakarta${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
}

print_ssh_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
   _____ _____ _    _     _______ ______ _      
  / ____|  __ \ |  | |   |__   __|  ____| |     
 | (___ | |__) | |__| |_____| |  | |__  | |     
  \___ \|  ___/|  __  ______| |  |  __| | |     
  ____) | |    | |  | |     | |  | |____| |____ 
 |_____/|_|    |_|  |_|     |_|  |______|______|
                                                
          SSH WS UDP MANAGEMENT
EOF
    echo -e "${NC}"
}

print_vmess_banner() {
    echo -e "${GREEN}"
    cat << "EOF"
 __      __ _    _     _______ ______ _      
 \ \    / /| |  | |   |__   __|  ____| |     
  \ \  / / | |__| |_____| |  | |__  | |     
   \ \/ /  |  __  ______| |  |  __| | |     
    \  /   | |  | |     | |  | |____| |____ 
     \/    |_|  |_|     |_|  |______|______|
                                            
           VMESS MANAGEMENT
EOF
    echo -e "${NC}"
}

print_vless_banner() {
    echo -e "${PURPLE}"
    cat << "EOF"
 __      __ _    _     _______ ______ _      
 \ \    / /| |  | |   |__   __|  ____| |     
  \ \  / / | |__| |_____| |  | |__  | |     
   \ \/ /  |  __  ______| |  |  __| | |     
    \  /   | |  | |     | |  | |____| |____ 
     \/    |_|  |_|     |_|  |______|______|
                                            
           VLESS MANAGEMENT
EOF
    echo -e "${NC}"
}

print_trojan_banner() {
    echo -e "${ORANGE}"
    cat << "EOF"
  _______           _        _______ ______ _      
 |__   __|         | |      |__   __|  ____| |     
    | |_ __ ___  __| | _____   | |  | |__  | |     
    | | '__/ _ \/ _` |/ / __|  | |  |  __| | |     
    | | | |  __/ (_|   <\__ \  | |  | |____| |____ 
    |_|_|  \___|\__,_|\_\___/  |_|  |______|______|
                                                   
              TROJAN MANAGEMENT
EOF
    echo -e "${NC}"
}

print_backup_banner() {
    echo -e "${YELLOW}"
    cat << "EOF"
  ____            _        ____              _    
 |  _ \          | |      |  _ \            | |   
 | |_) | __ _  __| | ___  | |_) | ___   ___ | | __
 |  _ < / _` |/ _` |/ _ \ |  _ < / _ \ / _ \| |/ /
 | |_) | (_| | (_| |  __/ | |_) | (_) | (_) |   < 
 |____/ \__,_|\__,_|\___| |____/ \___/ \___/|_|\_\
                                                  
             AUTO BACKUP SYSTEM
EOF
    echo -e "${NC}"
}

print_bandwidth_banner() {
    echo -e "${MAGENTA}"
    cat << "EOF"
  ____            _       _     _       _   _    _     
 |  _ \          | |     | |   | |     | | | |  | |    
 | |_) | __ _  __| | __ _| |__ | | __ _| |_| |__| |__  
 |  _ < / _` |/ _` |/ _` | '_ \| |/ _` | __|  __  '_ \ 
 | |_) | (_| | (_| | (_| | |_) | | (_| | |_| |  | | | |
 |____/ \__,_|\__,_|\__,_|_.__/|_|\__,_|\__|_|  |_| |_|
                                                       
               BANDWIDTH MONITOR
EOF
    echo -e "${NC}"
}