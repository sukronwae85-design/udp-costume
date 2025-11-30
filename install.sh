#!/bin/bash

# ==================================================
# UDP CUSTOM - INSTALLATION SCRIPT
# Author: Sukron Wae
# GitHub: https://github.com/sukronwae85-design/udp-custom
# ==================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Logging
LOG_FILE="/root/udp-install.log"

# Log function
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Print banner
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
    echo -e "${WHITE}    Author: Sukron Wae${NC}"
    echo -e "${WHITE}    GitHub: sukronwae85-design${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
}

# Check root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: Script harus dijalankan sebagai root!${NC}"
        exit 1
    fi
}

# Check OS
check_os() {
    echo -e "${YELLOW}[INFO] Checking operating system...${NC}"
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        OS=$(lsb_release -si 2>/dev/null || uname -o)
        VER=$(lsb_release -sr 2>/dev/null || uname -r)
    fi
    
    echo -e "${GREEN}[SUCCESS] OS Detected: $OS $VER${NC}"
    
    # Check if Ubuntu/Debian
    if [[ ! "$OS" =~ (Ubuntu|Debian) ]]; then
        echo -e "${RED}[ERROR] Script hanya support Ubuntu/Debian${NC}"
        exit 1
    fi
}

# Update system
update_system() {
    echo -e "${YELLOW}[INFO] Updating system packages...${NC}"
    apt-get update >> $LOG_FILE 2>&1
    apt-get upgrade -y >> $LOG_FILE 2>&1
    echo -e "${GREEN}[SUCCESS] System updated successfully${NC}"
}

# Install dependencies
install_dependencies() {
    echo -e "${YELLOW}[INFO] Installing dependencies...${NC}"
    
    apt-get install -y \
        curl wget git nano unzip tar \
        nginx apache2-utils \
        python3 python3-pip \
        jq net-tools iftop \
        cron dnsutils ufw \
        certbot software-properties-common \
        >> $LOG_FILE 2>&1
    
    # Install Docker untuk containerization
    curl -fsSL https://get.docker.com -o get-docker.sh >> $LOG_FILE 2>&1
    sh get-docker.sh >> $LOG_FILE 2>&1
    usermod -aG docker $USER >> $LOG_FILE 2>&1
    
    echo -e "${GREEN}[SUCCESS] Dependencies installed${NC}"
}

# Set timezone to Jakarta
set_timezone() {
    echo -e "${YELLOW}[INFO] Setting timezone to Jakarta...${NC}"
    timedatectl set-timezone Asia/Jakarta
    echo -e "${GREEN}[SUCCESS] Timezone set to Asia/Jakarta${NC}"
}

# Install UDP Custom
install_udp_custom() {
    echo -e "${YELLOW}[INFO] Installing UDP Custom Script...${NC}"
    
    # Copy main script
    cp udp-custom.sh /usr/local/bin/udp-custom
    chmod +x /usr/local/bin/udp-custom
    
    # Create directories
    mkdir -p /etc/udp-custom/{config,modules,lib,logs,backup}
    
    # Copy modules
    cp -r modules/* /etc/udp-custom/modules/
    cp -r lib/* /etc/udp-custom/lib/
    cp config.json /etc/udp-custom/config/
    
    # Set permissions
    chmod -R +x /etc/udp-custom/modules/
    chmod -R +x /etc/udp-custom/lib/
    
    echo -e "${GREEN}[SUCCESS] UDP Custom installed successfully${NC}"
}

# Create service
create_service() {
    echo -e "${YELLOW}[INFO] Creating systemd service...${NC}"
    
    cat > /etc/systemd/system/udp-custom.service << EOF
[Unit]
Description=UDP Custom Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/udp-custom
ExecStart=/usr/local/bin/udp-custom
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable udp-custom.service >> $LOG_FILE 2>&1
    
    echo -e "${GREEN}[SUCCESS] Service created and enabled${NC}"
}

# Setup cron jobs for auto backup
setup_cron() {
    echo -e "${YELLOW}[INFO] Setting up cron jobs...${NC}"
    
    # Backup every 6 hours
    (crontab -l 2>/dev/null; echo "0 */6 * * * /etc/udp-custom/modules/backup.sh auto") | crontab -
    
    # Update script daily
    (crontab -l 2>/dev/null; echo "0 2 * * * cd /etc/udp-custom && git pull") | crontab -
    
    echo -e "${GREEN}[SUCCESS] Cron jobs setup completed${NC}"
}

# Final setup
final_setup() {
    echo -e "${YELLOW}[INFO] Finalizing installation...${NC}"
    
    # Enable services
    systemctl enable nginx >> $LOG_FILE 2>&1
    systemctl start nginx >> $LOG_FILE 2>&1
    
    # Create default config
    if [ ! -f /etc/udp-custom/config/config.json ]; then
        cat > /etc/udp-custom/config/config.json << EOF
{
    "server": {
        "timezone": "Asia/Jakarta",
        "auto_backup": true,
        "backup_interval": "6h"
    },
    "services": {
        "ssh": {"enabled": true, "port": 22},
        "vmess": {"enabled": true, "port": 443},
        "vless": {"enabled": true, "port": 2083},
        "trojan": {"enabled": true, "port": 2087}
    },
    "backup": {
        "gmail": {"enabled": false},
        "whatsapp": {"enabled": false},
        "telegram": {"enabled": false}
    }
}
EOF
    fi
    
    echo -e "${GREEN}[SUCCESS] Final setup completed${NC}"
}

# Show completion message
show_completion() {
    clear
    print_banner
    echo -e "${GREEN}🎉 INSTALLATION COMPLETED SUCCESSFULLY!${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${WHITE}✅ UDP Custom Script Installed${NC}"
    echo -e "${WHITE}✅ System Timezone: Asia/Jakarta${NC}"
    echo -e "${WHITE}✅ Auto Backup Configured${NC}"
    echo -e "${WHITE}✅ All Dependencies Installed${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${YELLOW}🚀 Usage Instructions:${NC}"
    echo -e "${WHITE}1. Run command: udp-custom${NC}"
    echo -e "${WHITE}2. Or run: /usr/local/bin/udp-custom${NC}"
    echo -e "${WHITE}3. Service: systemctl status udp-custom${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${GREEN}📝 Log file: $LOG_FILE${NC}"
    echo ""
}

# Main installation
main_installation() {
    print_banner
    check_root
    check_os
    update_system
    set_timezone
    install_dependencies
    install_udp_custom
    create_service
    setup_cron
    final_setup
    show_completion
}

# Run installation
main_installation