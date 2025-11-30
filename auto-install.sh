#!/bin/bash

# ==================================================
# UDP CUSTOM - AUTO INSTALLER FROM GITHUB
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

# Variables
GITHUB_REPO="https://github.com/sukronwae85-design/udp-custom"
INSTALL_DIR="/etc/udp-custom"
SCRIPT_DIR="/usr/local/bin"
LOG_FILE="/root/udp-auto-install.log"

# Logging function
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
    echo -e "$1"
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
                                                 
           UDP CUSTOM - AUTO INSTALLER
        Install from GitHub Repository
EOF
    echo -e "${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${WHITE}    Repository: sukronwae85-design/udp-custom${NC}"
    echo -e "${WHITE}    Install Dir: $INSTALL_DIR${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
}

# Check root access
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log "${RED}Error: Script must be run as root!${NC}"
        log "Use: ${GREEN}sudo bash auto-install.sh${NC}"
        exit 1
    fi
}

# Check OS compatibility
check_os() {
    log "${YELLOW}[INFO] Checking operating system...${NC}"
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        OS=$(lsb_release -si 2>/dev/null || uname -o)
        VER=$(lsb_release -sr 2>/dev/null || uname -r)
    fi
    
    log "${GREEN}[SUCCESS] OS Detected: $OS $VER${NC}"
    
    # Check if Ubuntu/Debian
    if [[ ! "$OS" =~ (Ubuntu|Debian) ]]; then
        log "${RED}[ERROR] Script only supports Ubuntu/Debian${NC}"
        exit 1
    fi
}

# Install dependencies
install_dependencies() {
    log "${YELLOW}[INFO] Installing dependencies...${NC}"
    
    apt-get update >> $LOG_FILE 2>&1
    apt-get upgrade -y >> $LOG_FILE 2>&1
    
    # Install required packages
    apt-get install -y \
        curl wget git nano unzip tar \
        nginx apache2-utils \
        python3 python3-pip \
        jq net-tools iftop vnstat \
        cron dnsutils ufw \
        certbot software-properties-common \
        build-essential cmake libboost-system-dev libboost-program-options-dev libssl-dev \
        >> $LOG_FILE 2>&1
    
    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh >> $LOG_FILE 2>&1
    sh get-docker.sh >> $LOG_FILE 2>&1
    usermod -aG docker $USER >> $LOG_FILE 2>&1
    rm -f get-docker.sh
    
    log "${GREEN}[SUCCESS] Dependencies installed${NC}"
}

# Download from GitHub
download_from_github() {
    log "${YELLOW}[INFO] Downloading UDP Custom from GitHub...${NC}"
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd $TEMP_DIR
    
    # Download repository
    if git clone $GITHUB_REPO . >> $LOG_FILE 2>&1; then
        log "${GREEN}[SUCCESS] Repository downloaded successfully${NC}"
    else
        log "${RED}[ERROR] Failed to download from GitHub${NC}"
        log "Check: ${GREEN}https://github.com/sukronwae85-design/udp-custom${NC}"
        exit 1
    fi
}

# Install UDP Custom
install_udp_custom() {
    log "${YELLOW}[INFO] Installing UDP Custom Script...${NC}"
    
    # Create directories
    mkdir -p $INSTALL_DIR/{config,modules,lib,logs,backup}
    
    # Copy main script
    cp udp-custom.sh $SCRIPT_DIR/udp-custom
    chmod +x $SCRIPT_DIR/udp-custom
    
    # Copy modules
    cp -r modules/* $INSTALL_DIR/modules/
    cp -r lib/* $INSTALL_DIR/lib/
    
    # Copy config if exists
    if [ -f config.json ]; then
        cp config.json $INSTALL_DIR/config/
    else
        # Create default config
        create_default_config
    fi
    
    # Set permissions
    chmod -R +x $INSTALL_DIR/modules/
    chmod -R +x $INSTALL_DIR/lib/
    chmod +x $SCRIPT_DIR/udp-custom
    
    log "${GREEN}[SUCCESS] UDP Custom installed successfully${NC}"
}

# Create default config
create_default_config() {
    cat > $INSTALL_DIR/config/config.json << EOF
{
    "server": {
        "hostname": "$(hostname)",
        "ip_address": "$(curl -s ifconfig.me)",
        "timezone": "Asia/Jakarta",
        "auto_backup": true,
        "backup_interval": "6h"
    },
    "services": {
        "ssh": {
            "enabled": true,
            "port": 22,
            "udp_port": 7300,
            "ws_path": "/sshws"
        },
        "vmess": {
            "enabled": true,
            "port": 443,
            "uuid": "",
            "alter_id": 64
        },
        "vless": {
            "enabled": true,
            "port": 2083,
            "uuid": ""
        },
        "trojan": {
            "enabled": true,
            "port": 2087,
            "password": ""
        }
    },
    "limits": {
        "max_connections_per_user": 2,
        "auto_ban_time": 120,
        "default_download_limit": "unlimited",
        "default_upload_limit": "unlimited"
    },
    "backup": {
        "gmail": {
            "enabled": false,
            "email": "",
            "password": "",
            "interval": "24h"
        },
        "whatsapp": {
            "enabled": false,
            "phone_number": "",
            "interval": "24h"
        },
        "telegram": {
            "enabled": false,
            "bot_token": "",
            "chat_id": "",
            "interval": "24h"
        }
    },
    "monitoring": {
        "bandwidth_monitoring": true,
        "auto_restart_failed_services": true,
        "log_retention_days": 30
    }
}
EOF
}

# Set timezone to Jakarta
set_timezone() {
    log "${YELLOW}[INFO] Setting timezone to Jakarta...${NC}"
    timedatectl set-timezone Asia/Jakarta
    log "${GREEN}[SUCCESS] Timezone set to Asia/Jakarta${NC}"
}

# Create systemd service
create_service() {
    log "${YELLOW}[INFO] Creating systemd service...${NC}"
    
    cat > /etc/systemd/system/udp-custom.service << EOF
[Unit]
Description=UDP Custom Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$SCRIPT_DIR/udp-custom
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable udp-custom.service >> $LOG_FILE 2>&1
    
    log "${GREEN}[SUCCESS] Service created and enabled${NC}"
}

# Setup firewall
setup_firewall() {
    log "${YELLOW}[INFO] Setting up firewall...${NC}"
    
    # Enable UFW
    ufw --force enable >> $LOG_FILE 2>&1
    
    # Allow SSH
    ufw allow 22/tcp >> $LOG_FILE 2>&1
    
    # Allow UDP Custom ports
    ufw allow 443/tcp >> $LOG_FILE 2>&1    # Vmess
    ufw allow 2082/tcp >> $LOG_FILE 2>&1   # SSH WS
    ufw allow 2083/tcp >> $LOG_FILE 2>&1   # Vless
    ufw allow 2087/tcp >> $LOG_FILE 2>&1   # Trojan
    ufw allow 7300/udp >> $LOG_FILE 2>&1   # UDP Custom
    
    log "${GREEN}[SUCCESS] Firewall configured${NC}"
}

# Setup cron jobs
setup_cron() {
    log "${YELLOW}[INFO] Setting up cron jobs...${NC}"
    
    # Backup every 6 hours
    (crontab -l 2>/dev/null; echo "0 */6 * * * $INSTALL_DIR/modules/backup.sh auto") | crontab -
    
    # Update script daily
    (crontab -l 2>/dev/null; echo "0 2 * * * cd $INSTALL_DIR && git pull") | crontab -
    
    # Auto cleanup logs weekly
    (crontab -l 2>/dev/null; echo "0 3 * * 0 find $INSTALL_DIR/logs -name \"*.log\" -mtime +30 -delete") | crontab -
    
    log "${GREEN}[SUCCESS] Cron jobs setup completed${NC}"
}

# Final setup
final_setup() {
    log "${YELLOW}[INFO] Finalizing installation...${NC}"
    
    # Enable services
    systemctl enable nginx >> $LOG_FILE 2>&1
    systemctl start nginx >> $LOG_FILE 2>&1
    
    # Set proper permissions
    chown -R root:root $INSTALL_DIR
    chmod -R 755 $INSTALL_DIR
    
    log "${GREEN}[SUCCESS] Final setup completed${NC}"
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
    echo -e "${WHITE}✅ Firewall Configured${NC}"
    echo -e "${WHITE}✅ Services Enabled${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${YELLOW}🚀 Usage Instructions:${NC}"
    echo -e "${WHITE}1. Run command: ${GREEN}udp-custom${NC}"
    echo -e "${WHITE}2. Or run: ${GREEN}$SCRIPT_DIR/udp-custom${NC}"
    echo -e "${WHITE}3. Service: ${GREEN}systemctl status udp-custom${NC}"
    echo -e "${WHITE}4. Logs: ${GREEN}journalctl -u udp-custom -f${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${GREEN}📝 Installation log: $LOG_FILE${NC}"
    echo -e "${GREEN}📁 Install directory: $INSTALL_DIR${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo ""
    
    # Show next steps
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "1. Run ${GREEN}udp-custom${NC} to start configuration"
    echo -e "2. Configure your domains in menu options"
    echo -e "3. Set up backup notifications if needed"
    echo -e "4. Monitor bandwidth usage"
    echo ""
}

# Cleanup temporary files
cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf $TEMP_DIR
    fi
}

# Main installation function
main_installation() {
    print_banner
    check_root
    check_os
    install_dependencies
    set_timezone
    download_from_github
    install_udp_custom
    create_service
    setup_firewall
    setup_cron
    final_setup
    cleanup
    show_completion
}

# Handle errors
handle_error() {
    log "${RED}[ERROR] Installation failed!${NC}"
    log "Check the log file: $LOG_FILE"
    cleanup
    exit 1
}

# Set error trap
trap handle_error ERR

# Run installation
main_installation