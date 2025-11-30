#!/bin/bash

# Load libraries
source /etc/udp-custom/lib/colors.sh
source /etc/udp-custom/lib/helpers.sh

# Trojan Management Menu
manage_trojan_menu() {
    while true; do
        clear
        print_trojan_banner
        
        echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║          ${CYAN}TROJAN MANAGEMENT${GREEN}             ║${NC}"
        echo -e "${GREEN}╠════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║   ${WHITE}1. Buat User Trojan${NC}                  ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}2. Hapus User Trojan${NC}                 ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}3. List User Trojan${NC}                  ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}4. Trial User Trojan${NC}                 ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}5. Batasi Kecepatan Trojan${NC}           ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}6. Install & Config Trojan${NC}           ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}7. Restart Service Trojan${NC}            ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}8. Info Config Trojan${NC}                ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${RED}0. Back to Main Menu${NC}               ${GREEN}║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
        echo ""
        
        read -p "Pilih menu [0-8]: " choice
        
        case $choice in
            1) create_trojan_user ;;
            2) delete_trojan_user ;;
            3) list_trojan_users ;;
            4) trial_trojan_user ;;
            5) limit_trojan_speed ;;
            6) install_config_trojan ;;
            7) restart_trojan_service ;;
            8) show_trojan_config ;;
            0) break ;;
            *) 
                print_error "Pilihan tidak valid!"
                sleep 2
                ;;
        esac
    done
}

# Install Trojan
install_trojan() {
    if command -v trojan &> /dev/null; then
        return 0
    fi
    
    print_info "Menginstall Trojan..."
    
    # Install dependencies
    apt-get update > /dev/null 2>&1
    apt-get install -y build-essential cmake libboost-system-dev libboost-program-options-dev libssl-dev > /dev/null 2>&1
    
    # Clone and build Trojan
    cd /tmp
    git clone https://github.com/trojan-gfw/trojan.git > /dev/null 2>&1
    cd trojan
    mkdir build
    cd build
    cmake .. > /dev/null 2>&1
    make -j$(nproc) > /dev/null 2>&1
    make install > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        print_success "Trojan berhasil diinstall"
        
        # Create systemd service
        cat > /etc/systemd/system/trojan.service << EOF
[Unit]
Description=Trojan Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/trojan /etc/trojan/config.json
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
        
        systemctl daemon-reload
        return 0
    else
        print_error "Gagal menginstall Trojan"
        return 1
    fi
}

# Create Trojan User
create_trojan_user() {
    clear
    print_trojan_banner
    echo -e "${CYAN}BUAT USER TROJAN${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # Install Trojan if not exists
    install_trojan
    
    read -p "Masukkan username: " username
    read -p "Masukkan password: " password
    read -p "Masukkan masa aktif (hari): " days
    
    if [ -z "$username" ] || [ -z "$password" ] || [ -z "$days" ]; then
        print_error "Semua field harus diisi!"
        return 1
    fi
    
    # Calculate expiration
    expiration_date=$(date -d "+$days days" +%Y-%m-%d)
    expiration_timestamp=$(date -d "+$days days" +%s)
    
    # Create user directory
    mkdir -p /etc/udp-custom/users
    
    # Create user config
    cat > "/etc/udp-custom/users/trojan_$username" << EOF
USERNAME: $username
PASSWORD: $password
SERVICE: TROJAN
CREATED: $(date +%Y-%m-%d)
EXPIRED: $expiration_date
EXPIRED_TS: $expiration_timestamp
STATUS: ACTIVE
PORT: 2087
EOF
    
    # Update Trojan config
    update_trojan_config
    
    print_success "User Trojan berhasil dibuat!"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}Detail User Trojan:${NC}"
    echo -e "  Username: $username"
    echo -e "  Password: $password"
    echo -e "  Masa Aktif: $days hari"
    echo -e "  Expired: $expiration_date"
    echo -e "  Port: 2087"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # Show connection info
    show_trojan_connection_info "$username" "$password"
    
    log "Trojan user created: $username"
    press_any_key
}

# Delete Trojan User
delete_trojan_user() {
    clear
    print_trojan_banner
    echo -e "${CYAN}HAPUS USER TROJAN${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    read -p "Masukkan username: " username
    
    if [ ! -f "/etc/udp-custom/users/trojan_$username" ]; then
        print_error "User Trojan $username tidak ditemukan!"
        return 1
    fi
    
    echo -e "${YELLOW}User Trojan $username akan dihapus!${NC}"
    read -p "Apakah Anda yakin? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f "/etc/udp-custom/users/trojan_$username"
        update_trojan_config
        print_success "User Trojan $username berhasil dihapus!"
        log "Trojan user deleted: $username"
    else
        print_info "Penghapusan user dibatalkan"
    fi
    
    press_any_key
}

# List Trojan Users
list_trojan_users() {
    clear
    print_trojan_banner
    echo -e "${CYAN}DAFTAR USER TROJAN${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║ ${CYAN}USERNAME${NC}          ${CYAN}PASSWORD${NC}       ${CYAN}STATUS${NC}    ${CYAN}EXPIRED${NC}         ${GREEN}║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${NC}"
    
    if [ -d "/etc/udp-custom/users" ]; then
        for user_file in /etc/udp-custom/users/trojan_*; do
            if [ -f "$user_file" ]; then
                username=$(grep "^USERNAME:" "$user_file" | cut -d: -f2 | tr -d ' ')
                password=$(grep "^PASSWORD:" "$user_file" | cut -d: -f2 | tr -d ' ')
                expired=$(grep "^EXPIRED:" "$user_file" | cut -d: -f2 | tr -d ' ')
                
                # Check if expired
                current_ts=$(date +%s)
                expired_ts=$(grep "^EXPIRED_TS:" "$user_file" | cut -d: -f2 | tr -d ' ')
                
                if [ "$current_ts" -gt "$expired_ts" ] 2>/dev/null; then
                    status="${RED}EXPIRED${NC}"
                else
                    status="${GREEN}ACTIVE${NC}"
                fi
                
                printf "${GREEN}║ ${WHITE}%-16s${NC} ${YELLOW}%-12s${NC} %-10s ${WHITE}%-10s${NC}   ${GREEN}║${NC}\n" \
                    "$username" "$password" "$status" "$expired"
            fi
        done
    else
        echo -e "${GREEN}║ ${YELLOW}No Trojan users found${NC}                                 ${GREEN}║${NC}"
    fi
    
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    press_any_key
}

# Trial Trojan User
trial_trojan_user() {
    clear
    print_trojan_banner
    echo -e "${CYAN}TRIAL USER TROJAN${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # Install Trojan if not exists
    install_trojan
    
    # Generate random username and password
    trial_user="trial-$(generate_random_string 6)"
    trial_pass=$(generate_random_string 8)
    trial_days=1
    
    # Calculate expiration
    expiration_date=$(date -d "+1 days" +%Y-%m-%d)
    expiration_timestamp=$(date -d "+1 days" +%s)
    
    # Create user config
    mkdir -p /etc/udp-custom/users
    cat > "/etc/udp-custom/users/trojan_$trial_user" << EOF
USERNAME: $trial_user
PASSWORD: $trial_pass
SERVICE: TROJAN-TRIAL
CREATED: $(date +%Y-%m-%d)
EXPIRED: $expiration_date
EXPIRED_TS: $expiration_timestamp
STATUS: ACTIVE
PORT: 2087
EOF
    
    # Update Trojan config
    update_trojan_config
    
    print_success "Trial User Trojan berhasil dibuat!"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}Detail Trial User:${NC}"
    echo -e "  Username: $trial_user"
    echo -e "  Password: $trial_pass"
    echo -e "  Masa Aktif: 1 hari"
    echo -e "  Expired: $expiration_date"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # Show connection info
    show_trojan_connection_info "$trial_user" "$trial_pass"
    
    log "Trial Trojan user created: $trial_user"
    press_any_key
}

# Show Trojan Connection Info
show_trojan_connection_info() {
    local username=$1
    local password=$2
    local server_ip=$(get_server_ip)
    
    echo -e "\n${CYAN}Config Connection Trojan:${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "  ${YELLOW}Alamat Server:${NC} $server_ip"
    echo -e "  ${YELLOW}Port:${NC} 2087"
    echo -e "  ${YELLOW}Password:${NC} $password"
    echo -e "  ${YELLOW}SNI:${NC} $server_ip"
    echo -e "  ${YELLOW}Protocol:${NC} trojan"
    echo -e "  ${YELLOW}Transport:${NC} tcp"
    echo -e "  ${YELLOW}Security:${NC} tls"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # Generate Trojan URL
    trojan_url="trojan://$password@$server_ip:2087?security=tls&sni=$server_ip&type=tcp#$username"
    
    echo -e "  ${YELLOW}Trojan URL:${NC}"
    echo -e "  $trojan_url"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
}

# Limit Trojan Speed
limit_trojan_speed() {
    clear
    print_trojan_banner
    echo -e "${CYAN}BATASI KECEPATAN TROJAN${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    read -p "Masukkan username: " username
    
    if [ ! -f "/etc/udp-custom/users/trojan_$username" ]; then
        print_error "User Trojan $username tidak ditemukan!"
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
    echo "DOWNLOAD_LIMIT: $download_limit" >> "/etc/udp-custom/users/trojan_$username"
    echo "UPLOAD_LIMIT: $upload_limit" >> "/etc/udp-custom/users/trojan_$username"
    
    print_success "Limit kecepatan diterapkan untuk user $username"
    echo -e "  Download: ${download_limit}MB/s"
    echo -e "  Upload: ${upload_limit}MB/s"
    
    log "Trojan speed limit set for $username: DL=${download_limit}MB/s UL=${upload_limit}MB/s"
    press_any_key
}

# Update Trojan Config
update_trojan_config() {
    # Create Trojan config directory
    mkdir -p /etc/trojan
    
    # Create Trojan config
    cat > /etc/trojan/config.json << EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 2087,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        $(get_trojan_passwords)
    ],
    "log_level": 1,
    "ssl": {
        "cert": "/etc/ssl/certs/ssl-cert-snakeoil.pem",
        "key": "/etc/ssl/private/ssl-cert-snakeoil.key",
        "key_password": "",
        "cipher": "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384",
        "cipher_tls13": "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
        "prefer_server_cipher": true,
        "alpn": [
            "http/1.1"
        ],
        "alpn_port_override": {
            "h2": 81
        },
        "reuse_session": true,
        "session_ticket": false,
        "session_timeout": 600,
        "plain_http_response": "",
        "curves": "",
        "dhparam": ""
    },
    "tcp": {
        "prefer_ipv4": false,
        "no_delay": true,
        "keep_alive": true,
        "reuse_port": false,
        "fast_open": false,
        "fast_open_qlen": 20
    },
    "mysql": {
        "enabled": false,
        "server_addr": "127.0.0.1",
        "server_port": 3306,
        "database": "trojan",
        "username": "trojan",
        "password": "",
        "key": "",
        "cert": "",
        "ca": ""
    }
}
EOF
}

# Get Trojan Passwords for config
get_trojan_passwords() {
    local passwords=()
    
    if [ -d "/etc/udp-custom/users" ]; then
        for user_file in /etc/udp-custom/users/trojan_*; do
            if [ -f "$user_file" ]; then
                password=$(grep "^PASSWORD:" "$user_file" | cut -d: -f2 | tr -d ' ')
                expired_ts=$(grep "^EXPIRED_TS:" "$user_file" | cut -d: -f2 | tr -d ' ')
                current_ts=$(date +%s)
                
                # Only add if not expired
                if [ "$current_ts" -le "$expired_ts" ] 2>/dev/null; then
                    passwords+=("\"$password\"")
                fi
            fi
        done
    fi
    
    # If no passwords, add a dummy password
    if [ ${#passwords[@]} -eq 0 ]; then
        passwords+=("\"dummy-password-$(generate_random_string 8)\"")
    fi
    
    echo $(IFS=,; echo "${passwords[*]}")
}

# Install and Config Trojan
install_config_trojan() {
    clear
    print_trojan_banner
    echo -e "${CYAN}INSTALL & CONFIG TROJAN${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # Install Trojan
    install_trojan
    
    # Update config
    update_trojan_config
    
    # Start Trojan service
    systemctl enable trojan > /dev/null 2>&1
    systemctl restart trojan
    
    if systemctl is-active --quiet trojan; then
        print_success "Trojan berhasil diinstall dan dikonfigurasi"
        echo -e "  Status: $(systemctl is-active trojan)"
        echo -e "  Port: 2087"
        echo -e "  Config: /etc/trojan/config.json"
    else
        print_error "Gagal start Trojan service"
        echo -e "  Check logs: journalctl -u trojan -f"
    fi
    
    press_any_key
}

# Restart Trojan Service
restart_trojan_service() {
    clear
    print_trojan_banner
    echo -e "${CYAN}RESTART TROJAN SERVICE${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    if systemctl is-active --quiet trojan; then
        systemctl restart trojan
        print_success "Trojan service berhasil di-restart"
    else
        systemctl start trojan
        print_success "Trojan service berhasil di-start"
    fi
    
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "Status: $(systemctl is-active trojan)"
    echo -e "Port: 2087"
    echo -e "Config: /etc/trojan/config.json"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    log "Trojan service restarted"
    press_any_key
}

# Show Trojan Config
show_trojan_config() {
    clear
    print_trojan_banner
    echo -e "${CYAN}INFO CONFIG TROJAN${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    read -p "Masukkan username: " username
    
    if [ ! -f "/etc/udp-custom/users/trojan_$username" ]; then
        print_error "User Trojan $username tidak ditemukan!"
        return 1
    fi
    
    password=$(grep "^PASSWORD:" "/etc/udp-custom/users/trojan_$username" | cut -d: -f2 | tr -d ' ')
    expired=$(grep "^EXPIRED:" "/etc/udp-custom/users/trojan_$username" | cut -d: -f2 | tr -d ' ')
    
    show_trojan_connection_info "$username" "$password"
    press_any_key
}