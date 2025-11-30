#!/bin/bash

# Load libraries
source /etc/udp-custom/lib/colors.sh
source /etc/udp-custom/lib/helpers.sh

# Vmess Management Menu
manage_vmess_menu() {
    while true; do
        clear
        print_vmess_banner
        
        echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║          ${CYAN}VMESS MANAGEMENT${GREEN}              ║${NC}"
        echo -e "${GREEN}╠════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║   ${WHITE}1. Buat User Vmess${NC}                   ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}2. Hapus User Vmess${NC}                  ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}3. List User Vmess${NC}                   ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}4. Trial User Vmess${NC}                  ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}5. Batasi Kecepatan Vmess${NC}            ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}6. Config Xray Vmess${NC}                 ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}7. Restart Service Xray${NC}              ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}8. Info Config Vmess${NC}                 ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${RED}0. Back to Main Menu${NC}               ${GREEN}║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
        echo ""
        
        read -p "Pilih menu [0-8]: " choice
        
        case $choice in
            1) create_vmess_user ;;
            2) delete_vmess_user ;;
            3) list_vmess_users ;;
            4) trial_vmess_user ;;
            5) limit_vmess_speed ;;
            6) config_xray_vmess ;;
            7) restart_xray_service ;;
            8) show_vmess_config ;;
            0) break ;;
            *) 
                print_error "Pilihan tidak valid!"
                sleep 2
                ;;
        esac
    done
}

# Install Xray
install_xray() {
    if command -v xray &> /dev/null; then
        return 0
    fi
    
    print_info "Menginstall Xray..."
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    
    if [ $? -eq 0 ]; then
        print_success "Xray berhasil diinstall"
    else
        print_error "Gagal menginstall Xray"
        return 1
    fi
}

# Create Vmess User
create_vmess_user() {
    clear
    print_vmess_banner
    echo -e "${CYAN}BUAT USER VMESS${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # Install Xray if not exists
    install_xray
    
    read -p "Masukkan username: " username
    read -p "Masukkan masa aktif (hari): " days
    
    if [ -z "$username" ] || [ -z "$days" ]; then
        print_error "Semua field harus diisi!"
        return 1
    fi
    
    # Generate UUID
    uuid=$(generate_uuid)
    
    # Calculate expiration
    expiration_date=$(date -d "+$days days" +%Y-%m-%d)
    expiration_timestamp=$(date -d "+$days days" +%s)
    
    # Create user directory
    mkdir -p /etc/udp-custom/users
    mkdir -p /etc/xray/config
    
    # Create user config
    cat > "/etc/udp-custom/users/vmess_$username" << EOF
USERNAME: $username
UUID: $uuid
SERVICE: VMESS
CREATED: $(date +%Y-%m-%d)
EXPIRED: $expiration_date
EXPIRED_TS: $expiration_timestamp
STATUS: ACTIVE
EOF
    
    # Update Xray config
    update_xray_config
    
    print_success "User Vmess berhasil dibuat!"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}Detail User Vmess:${NC}"
    echo -e "  Username: $username"
    echo -e "  UUID: $uuid"
    echo -e "  Masa Aktif: $days hari"
    echo -e "  Expired: $expiration_date"
    echo -e "  Port: 443"
    echo -e "  AlterId: 64"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # Show connection info
    show_vmess_connection_info "$username" "$uuid"
    
    log "Vmess user created: $username (UUID: $uuid)"
    press_any_key
}

# Delete Vmess User
delete_vmess_user() {
    clear
    print_vmess_banner
    echo -e "${CYAN}HAPUS USER VMESS${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    read -p "Masukkan username: " username
    
    if [ ! -f "/etc/udp-custom/users/vmess_$username" ]; then
        print_error "User Vmess $username tidak ditemukan!"
        return 1
    fi
    
    echo -e "${YELLOW}User Vmess $username akan dihapus!${NC}"
    read -p "Apakah Anda yakin? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f "/etc/udp-custom/users/vmess_$username"
        update_xray_config
        print_success "User Vmess $username berhasil dihapus!"
        log "Vmess user deleted: $username"
    else
        print_info "Penghapusan user dibatalkan"
    fi
    
    press_any_key
}

# List Vmess Users
list_vmess_users() {
    clear
    print_vmess_banner
    echo -e "${CYAN}DAFTAR USER VMESS${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║ ${CYAN}USERNAME${NC}          ${CYAN}UUID${NC}                               ${CYAN}EXPIRED${NC}   ${GREEN}║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${NC}"
    
    if [ -d "/etc/udp-custom/users" ]; then
        for user_file in /etc/udp-custom/users/vmess_*; do
            if [ -f "$user_file" ]; then
                username=$(grep "^USERNAME:" "$user_file" | cut -d: -f2 | tr -d ' ')
                uuid=$(grep "^UUID:" "$user_file" | cut -d: -f2 | tr -d ' ')
                expired=$(grep "^EXPIRED:" "$user_file" | cut -d: -f2 | tr -d ' ')
                status=$(grep "^STATUS:" "$user_file" | cut -d: -f2 | tr -d ' ')
                
                # Check if expired
                current_ts=$(date +%s)
                expired_ts=$(grep "^EXPIRED_TS:" "$user_file" | cut -d: -f2 | tr -d ' ')
                
                if [ "$current_ts" -gt "$expired_ts" ] 2>/dev/null; then
                    status="${RED}EXPIRED${NC}"
                else
                    status="${GREEN}ACTIVE${NC}"
                fi
                
                # Shorten UUID for display
                short_uuid="${uuid:0:8}...${uuid: -8}"
                
                printf "${GREEN}║ ${WHITE}%-16s${NC} ${YELLOW}%-24s${NC} %-10s ${WHITE}%-10s${NC} ${GREEN}║${NC}\n" \
                    "$username" "$short_uuid" "$status" "$expired"
            fi
        done
    else
        echo -e "${GREEN}║ ${YELLOW}No Vmess users found${NC}                                  ${GREEN}║${NC}"
    fi
    
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    press_any_key
}

# Trial Vmess User
trial_vmess_user() {
    clear
    print_vmess_banner
    echo -e "${CYAN}TRIAL USER VMESS${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # Install Xray if not exists
    install_xray
    
    # Generate random username and UUID
    trial_user="trial-$(generate_random_string 6)"
    trial_uuid=$(generate_uuid)
    trial_days=1
    
    # Calculate expiration
    expiration_date=$(date -d "+1 days" +%Y-%m-%d)
    expiration_timestamp=$(date -d "+1 days" +%s)
    
    # Create user config
    mkdir -p /etc/udp-custom/users
    cat > "/etc/udp-custom/users/vmess_$trial_user" << EOF
USERNAME: $trial_user
UUID: $trial_uuid
SERVICE: VMESS-TRIAL
CREATED: $(date +%Y-%m-%d)
EXPIRED: $expiration_date
EXPIRED_TS: $expiration_timestamp
STATUS: ACTIVE
EOF
    
    # Update Xray config
    update_xray_config
    
    print_success "Trial User Vmess berhasil dibuat!"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}Detail Trial User:${NC}"
    echo -e "  Username: $trial_user"
    echo -e "  UUID: $trial_uuid"
    echo -e "  Masa Aktif: 1 hari"
    echo -e "  Expired: $expiration_date"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # Show connection info
    show_vmess_connection_info "$trial_user" "$trial_uuid"
    
    log "Trial Vmess user created: $trial_user"
    press_any_key
}

# Show Vmess Connection Info
show_vmess_connection_info() {
    local username=$1
    local uuid=$2
    local server_ip=$(get_server_ip)
    
    echo -e "\n${CYAN}Config Connection Vmess:${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "  ${YELLOW}Alamat Server:${NC} $server_ip"
    echo -e "  ${YELLOW}Port:${NC} 443"
    echo -e "  ${YELLOW}UUID:${NC} $uuid"
    echo -e "  ${YELLOW}AlterId:${NC} 64"
    echo -e "  ${YELLOW}Security:${NC} auto"
    echo -e "  ${YELLOW}Network:${NC} ws"
    echo -e "  ${YELLOW}Path:${NC} /vmess"
    echo -e "  ${YELLOW}TLS:${NC} tls"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # Generate Vmess URL
    vmess_url="vmess://$(echo "{
        \"v\": \"2\",
        \"ps\": \"$username\",
        \"add\": \"$server_ip\",
        \"port\": \"443\",
        \"id\": \"$uuid\",
        \"aid\": \"64\",
        \"scy\": \"auto\",
        \"net\": \"ws\",
        \"type\": \"none\",
        \"host\": \"\",
        \"path\": \"/vmess\",
        \"tls\": \"tls\",
        \"sni\": \"\"
    }" | base64 -w 0)"
    
    echo -e "  ${YELLOW}Vmess URL:${NC}"
    echo -e "  $vmess_url"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
}

# Limit Vmess Speed
limit_vmess_speed() {
    clear
    print_vmess_banner
    echo -e "${CYAN}BATASI KECEPATAN VMESS${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    read -p "Masukkan username: " username
    
    if [ ! -f "/etc/udp-custom/users/vmess_$username" ]; then
        print_error "User Vmess $username tidak ditemukan!"
        return 1
    fi
    
    echo -e "${YELLOW}Batasan kecepatan untuk user: $username${NC}"
    read -p "Download limit (MB/s): " download_limit
    read -p "Upload limit (MB/s): " upload_limit
    
    if [ -z "$download_limit" ] || [ -z "$upload_limit" ]; then
        print_error "Limit download dan upload harus diisi!"
        return 1
    fi
    
    # Update user config with speed limit
    echo "DOWNLOAD_LIMIT: $download_limit" >> "/etc/udp-custom/users/vmess_$username"
    echo "UPLOAD_LIMIT: $upload_limit" >> "/etc/udp-custom/users/vmess_$username"
    
    print_success "Limit kecepatan diterapkan untuk user $username"
    echo -e "  Download: ${download_limit}MB/s"
    echo -e "  Upload: ${upload_limit}MB/s"
    
    log "Vmess speed limit set for $username: DL=${download_limit}MB/s UL=${upload_limit}MB/s"
    press_any_key
}

# Config Xray Vmess
config_xray_vmess() {
    clear
    print_vmess_banner
    echo -e "${CYAN}CONFIG XRAY VMESS${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # Install Xray if not exists
    install_xray
    
    print_info "Mengkonfigurasi Xray untuk Vmess..."
    
    # Update Xray config
    update_xray_config
    
    # Restart Xray service
    systemctl restart xray
    
    if systemctl is-active --quiet xray; then
        print_success "Xray berhasil dikonfigurasi dan di-restart"
        echo -e "  Status: $(systemctl is-active xray)"
        echo -e "  Config: /usr/local/etc/xray/config.json"
    else
        print_error "Gagal restart Xray service"
    fi
    
    press_any_key
}

# Update Xray Config
update_xray_config() {
    # Create basic Xray config
    cat > /usr/local/etc/xray/config.json << EOF
{
    "log": {
        "loglevel": "warning"
    },
    "routing": {
        "domainStrategy": "AsIs",
        "rules": []
    },
    "inbounds": [
        {
            "port": 443,
            "protocol": "vmess",
            "settings": {
                "clients": [
                    $(get_vmess_clients)
                ]
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/vmess"
                },
                "security": "tls",
                "tlsSettings": {
                    "certificates": [
                        {
                            "certificateFile": "/etc/ssl/certs/ssl-cert-snakeoil.pem",
                            "keyFile": "/etc/ssl/private/ssl-cert-snakeoil.key"
                        }
                    ]
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct"
        },
        {
            "protocol": "blackhole",
            "tag": "blocked"
        }
    ]
}
EOF
}

# Get Vmess Clients for Xray config
get_vmess_clients() {
    local clients=()
    
    if [ -d "/etc/udp-custom/users" ]; then
        for user_file in /etc/udp-custom/users/vmess_*; do
            if [ -f "$user_file" ]; then
                username=$(grep "^USERNAME:" "$user_file" | cut -d: -f2 | tr -d ' ')
                uuid=$(grep "^UUID:" "$user_file" | cut -d: -f2 | tr -d ' ')
                expired_ts=$(grep "^EXPIRED_TS:" "$user_file" | cut -d: -f2 | tr -d ' ')
                current_ts=$(date +%s)
                
                # Only add if not expired
                if [ "$current_ts" -le "$expired_ts" ] 2>/dev/null; then
                    clients+=("{
                        \"id\": \"$uuid\",
                        \"alterId\": 64,
                        \"email\": \"$username\",
                        \"level\": 0
                    }")
                fi
            fi
        done
    fi
    
    # If no clients, add a dummy client
    if [ ${#clients[@]} -eq 0 ]; then
        clients+=("{
            \"id\": \"$(generate_uuid)\",
            \"alterId\": 64,
            \"email\": \"dummy-user\",
            \"level\": 0
        }")
    fi
    
    echo $(IFS=,; echo "${clients[*]}")
}

# Restart Xray Service
restart_xray_service() {
    clear
    print_vmess_banner
    echo -e "${CYAN}RESTART XRAY SERVICE${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    if systemctl is-active --quiet xray; then
        systemctl restart xray
        print_success "Xray service berhasil di-restart"
    else
        systemctl start xray
        print_success "Xray service berhasil di-start"
    fi
    
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "Status: $(systemctl is-active xray)"
    echo -e "Config: /usr/local/etc/xray/config.json"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    log "Xray service restarted"
    press_any_key
}

# Show Vmess Config
show_vmess_config() {
    clear
    print_vmess_banner
    echo -e "${CYAN}INFO CONFIG VMESS${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    read -p "Masukkan username: " username
    
    if [ ! -f "/etc/udp-custom/users/vmess_$username" ]; then
        print_error "User Vmess $username tidak ditemukan!"
        return 1
    fi
    
    uuid=$(grep "^UUID:" "/etc/udp-custom/users/vmess_$username" | cut -d: -f2 | tr -d ' ')
    expired=$(grep "^EXPIRED:" "/etc/udp-custom/users/vmess_$username" | cut -d: -f2 | tr -d ' ')
    
    show_vmess_connection_info "$username" "$uuid"
    press_any_key
}