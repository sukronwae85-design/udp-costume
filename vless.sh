#!/bin/bash

# Load libraries
source /etc/udp-custom/lib/colors.sh
source /etc/udp-custom/lib/helpers.sh

# Vless Management Menu
manage_vless_menu() {
    while true; do
        clear
        print_vless_banner
        
        echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║          ${CYAN}VLESS MANAGEMENT${GREEN}              ║${NC}"
        echo -e "${GREEN}╠════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║   ${WHITE}1. Buat User Vless${NC}                   ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}2. Hapus User Vless${NC}                  ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}3. List User Vless${NC}                   ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}4. Trial User Vless${NC}                  ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}5. Batasi Kecepatan Vless${NC}            ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}6. Config Xray Vless${NC}                 ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}7. Restart Service Xray${NC}              ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}8. Info Config Vless${NC}                 ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${RED}0. Back to Main Menu${NC}               ${GREEN}║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
        echo ""
        
        read -p "Pilih menu [0-8]: " choice
        
        case $choice in
            1) create_vless_user ;;
            2) delete_vless_user ;;
            3) list_vless_users ;;
            4) trial_vless_user ;;
            5) limit_vless_speed ;;
            6) config_xray_vless ;;
            7) restart_xray_service_vless ;;
            8) show_vless_config ;;
            0) break ;;
            *) 
                print_error "Pilihan tidak valid!"
                sleep 2
                ;;
        esac
    done
}

# Create Vless User
create_vless_user() {
    clear
    print_vless_banner
    echo -e "${CYAN}BUAT USER VLESS${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # Install Xray if not exists
    if ! command -v xray &> /dev/null; then
        install_xray
    fi
    
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
    
    # Create user config
    cat > "/etc/udp-custom/users/vless_$username" << EOF
USERNAME: $username
UUID: $uuid
SERVICE: VLESS
CREATED: $(date +%Y-%m-%d)
EXPIRED: $expiration_date
EXPIRED_TS: $expiration_timestamp
STATUS: ACTIVE
PORT: 2083
FLOW: xtls-rprx-direct
EOF
    
    # Update Xray config for Vless
    update_xray_config_vless
    
    print_success "User Vless berhasil dibuat!"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}Detail User Vless:${NC}"
    echo -e "  Username: $username"
    echo -e "  UUID: $uuid"
    echo -e "  Masa Aktif: $days hari"
    echo -e "  Expired: $expiration_date"
    echo -e "  Port: 2083"
    echo -e "  Flow: xtls-rprx-direct"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # Show connection info
    show_vless_connection_info "$username" "$uuid"
    
    log "Vless user created: $username (UUID: $uuid)"
    press_any_key
}

# Delete Vless User
delete_vless_user() {
    clear
    print_vless_banner
    echo -e "${CYAN}HAPUS USER VLESS${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    read -p "Masukkan username: " username
    
    if [ ! -f "/etc/udp-custom/users/vless_$username" ]; then
        print_error "User Vless $username tidak ditemukan!"
        return 1
    fi
    
    echo -e "${YELLOW}User Vless $username akan dihapus!${NC}"
    read -p "Apakah Anda yakin? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f "/etc/udp-custom/users/vless_$username"
        update_xray_config_vless
        print_success "User Vless $username berhasil dihapus!"
        log "Vless user deleted: $username"
    else
        print_info "Penghapusan user dibatalkan"
    fi
    
    press_any_key
}

# List Vless Users
list_vless_users() {
    clear
    print_vless_banner
    echo -e "${CYAN}DAFTAR USER VLESS${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║ ${CYAN}USERNAME${NC}          ${CYAN}UUID${NC}                               ${CYAN}EXPIRED${NC}   ${GREEN}║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${NC}"
    
    if [ -d "/etc/udp-custom/users" ]; then
        for user_file in /etc/udp-custom/users/vless_*; do
            if [ -f "$user_file" ]; then
                username=$(grep "^USERNAME:" "$user_file" | cut -d: -f2 | tr -d ' ')
                uuid=$(grep "^UUID:" "$user_file" | cut -d: -f2 | tr -d ' ')
                expired=$(grep "^EXPIRED:" "$user_file" | cut -d: -f2 | tr -d ' ')
                port=$(grep "^PORT:" "$user_file" | cut -d: -f2 | tr -d ' ')
                
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
        echo -e "${GREEN}║ ${YELLOW}No Vless users found${NC}                                  ${GREEN}║${NC}"
    fi
    
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    press_any_key
}

# Trial Vless User
trial_vless_user() {
    clear
    print_vless_banner
    echo -e "${CYAN}TRIAL USER VLESS${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # Install Xray if not exists
    if ! command -v xray &> /dev/null; then
        install_xray
    fi
    
    # Generate random username and UUID
    trial_user="trial-$(generate_random_string 6)"
    trial_uuid=$(generate_uuid)
    trial_days=1
    
    # Calculate expiration
    expiration_date=$(date -d "+1 days" +%Y-%m-%d)
    expiration_timestamp=$(date -d "+1 days" +%s)
    
    # Create user config
    mkdir -p /etc/udp-custom/users
    cat > "/etc/udp-custom/users/vless_$trial_user" << EOF
USERNAME: $trial_user
UUID: $trial_uuid
SERVICE: VLESS-TRIAL
CREATED: $(date +%Y-%m-%d)
EXPIRED: $expiration_date
EXPIRED_TS: $expiration_timestamp
STATUS: ACTIVE
PORT: 2083
FLOW: xtls-rprx-direct
EOF
    
    # Update Xray config for Vless
    update_xray_config_vless
    
    print_success "Trial User Vless berhasil dibuat!"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}Detail Trial User:${NC}"
    echo -e "  Username: $trial_user"
    echo -e "  UUID: $trial_uuid"
    echo -e "  Masa Aktif: 1 hari"
    echo -e "  Expired: $expiration_date"
    echo -e "  Port: 2083"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # Show connection info
    show_vless_connection_info "$trial_user" "$trial_uuid"
    
    log "Trial Vless user created: $trial_user"
    press_any_key
}

# Show Vless Connection Info
show_vless_connection_info() {
    local username=$1
    local uuid=$2
    local server_ip=$(get_server_ip)
    
    echo -e "\n${CYAN}Config Connection Vless:${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "  ${YELLOW}Alamat Server:${NC} $server_ip"
    echo -e "  ${YELLOW}Port:${NC} 2083"
    echo -e "  ${YELLOW}UUID:${NC} $uuid"
    echo -e "  ${YELLOW}Flow:${NC} xtls-rprx-direct"
    echo -e "  ${YELLOW}Encryption:${NC} none"
    echo -e "  ${YELLOW}Network:${NC} tcp"
    echo -e "  ${YELLOW}Security:${NC} xtls"
    echo -e "  ${YELLOW}Type:${NC} none"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # Generate Vless URL
    vless_url="vless://$uuid@$server_ip:2083?encryption=none&flow=xtls-rprx-direct&security=xtls&type=tcp#${username}"
    
    echo -e "  ${YELLOW}Vless URL:${NC}"
    echo -e "  $vless_url"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
}

# Limit Vless Speed
limit_vless_speed() {
    clear
    print_vless_banner
    echo -e "${CYAN}BATASI KECEPATAN VLESS${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    read -p "Masukkan username: " username
    
    if [ ! -f "/etc/udp-custom/users/vless_$username" ]; then
        print_error "User Vless $username tidak ditemukan!"
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
    echo "DOWNLOAD_LIMIT: $download_limit" >> "/etc/udp-custom/users/vless_$username"
    echo "UPLOAD_LIMIT: $upload_limit" >> "/etc/udp-custom/users/vless_$username"
    
    print_success "Limit kecepatan diterapkan untuk user $username"
    echo -e "  Download: ${download_limit}MB/s"
    echo -e "  Upload: ${upload_limit}MB/s"
    
    log "Vless speed limit set for $username: DL=${download_limit}MB/s UL=${upload_limit}MB/s"
    press_any_key
}

# Update Xray Config for Vless
update_xray_config_vless() {
    # Check if Xray config exists
    if [ ! -f "/usr/local/etc/xray/config.json" ]; then
        # Create new config with both Vmess and Vless
        update_xray_config
        return
    fi
    
    # Backup original config
    cp /usr/local/etc/xray/config.json /usr/local/etc/xray/config.json.backup
    
    # Create new config with Vless inbound
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
        },
        {
            "port": 2083,
            "protocol": "vless",
            "settings": {
                "clients": [
                    $(get_vless_clients)
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "xtls",
                "xtlsSettings": {
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

# Get Vless Clients for Xray config
get_vless_clients() {
    local clients=()
    
    if [ -d "/etc/udp-custom/users" ]; then
        for user_file in /etc/udp-custom/users/vless_*; do
            if [ -f "$user_file" ]; then
                username=$(grep "^USERNAME:" "$user_file" | cut -d: -f2 | tr -d ' ')
                uuid=$(grep "^UUID:" "$user_file" | cut -d: -f2 | tr -d ' ')
                expired_ts=$(grep "^EXPIRED_TS:" "$user_file" | cut -d: -f2 | tr -d ' ')
                current_ts=$(date +%s)
                flow=$(grep "^FLOW:" "$user_file" | cut -d: -f2 | tr -d ' ')
                
                # Only add if not expired
                if [ "$current_ts" -le "$expired_ts" ] 2>/dev/null; then
                    clients+=("{
                        \"id\": \"$uuid\",
                        \"email\": \"$username\",
                        \"level\": 0,
                        \"flow\": \"$flow\"
                    }")
                fi
            fi
        done
    fi
    
    # If no clients, add a dummy client
    if [ ${#clients[@]} -eq 0 ]; then
        clients+=("{
            \"id\": \"$(generate_uuid)\",
            \"email\": \"dummy-vless-user\",
            \"level\": 0,
            \"flow\": \"xtls-rprx-direct\"
        }")
    fi
    
    echo $(IFS=,; echo "${clients[*]}")
}

# Config Xray Vless
config_xray_vless() {
    clear
    print_vless_banner
    echo -e "${CYAN}CONFIG XRAY VLESS${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # Install Xray if not exists
    if ! command -v xray &> /dev/null; then
        install_xray
    fi
    
    print_info "Mengkonfigurasi Xray untuk Vless..."
    
    # Update Xray config
    update_xray_config_vless
    
    # Restart Xray service
    systemctl restart xray
    
    if systemctl is-active --quiet xray; then
        print_success "Xray Vless berhasil dikonfigurasi dan di-restart"
        echo -e "  Status: $(systemctl is-active xray)"
        echo -e "  Vless Port: 2083"
        echo -e "  Config: /usr/local/etc/xray/config.json"
    else
        print_error "Gagal restart Xray service"
    fi
    
    press_any_key
}

# Restart Xray Service for Vless
restart_xray_service_vless() {
    clear
    print_vless_banner
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
    echo -e "Vless Port: 2083"
    echo -e "Config: /usr/local/etc/xray/config.json"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    log "Xray service restarted for Vless"
    press_any_key
}

# Show Vless Config
show_vless_config() {
    clear
    print_vless_banner
    echo -e "${CYAN}INFO CONFIG VLESS${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    read -p "Masukkan username: " username
    
    if [ ! -f "/etc/udp-custom/users/vless_$username" ]; then
        print_error "User Vless $username tidak ditemukan!"
        return 1
    fi
    
    uuid=$(grep "^UUID:" "/etc/udp-custom/users/vless_$username" | cut -d: -f2 | tr -d ' ')
    expired=$(grep "^EXPIRED:" "/etc/udp-custom/users/vless_$username" | cut -d: -f2 | tr -d ' ')
    flow=$(grep "^FLOW:" "/etc/udp-custom/users/vless_$username" | cut -d: -f2 | tr -d ' ')
    
    show_vless_connection_info "$username" "$uuid"
    press_any_key
}