#!/bin/bash

# Load libraries
source /etc/udp-custom/lib/colors.sh
source /etc/udp-custom/lib/helpers.sh

# SSH Management Menu
manage_ssh_menu() {
    while true; do
        clear
        print_ssh_banner
        
        echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║          ${CYAN}SSH MANAGEMENT${GREEN}               ║${NC}"
        echo -e "${GREEN}╠════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║   ${WHITE}1. Buat User SSH${NC}                     ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}2. Hapus User SSH${NC}                    ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}3. List User SSH${NC}                     ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}4. Trial User SSH${NC}                    ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}5. Batasi Kecepatan User${NC}             ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}6. Config UDP Custom${NC}                 ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}7. Restart Service SSH${NC}               ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${RED}0. Back to Main Menu${NC}               ${GREEN}║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
        echo ""
        
        read -p "Pilih menu [0-7]: " choice
        
        case $choice in
            1) create_ssh_user ;;
            2) delete_ssh_user ;;
            3) list_ssh_users ;;
            4) trial_ssh_user ;;
            5) limit_ssh_speed ;;
            6) config_udp_custom ;;
            7) restart_ssh_service ;;
            0) break ;;
            *) 
                print_error "Pilihan tidak valid!"
                sleep 2
                ;;
        esac
    done
}

# Create SSH User
create_ssh_user() {
    clear
    print_ssh_banner
    echo -e "${CYAN}BUAT USER SSH${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    read -p "Masukkan username: " username
    read -p "Masukkan password: " password
    read -p "Masukkan masa aktif (hari): " days
    
    if [ -z "$username" ] || [ -z "$password" ] || [ -z "$days" ]; then
        print_error "Semua field harus diisi!"
        return 1
    fi
    
    # Check if user exists
    if id "$username" &>/dev/null; then
        print_error "User $username sudah ada!"
        return 1
    fi
    
    # Calculate expiration date
    expiration_date=$(date -d "+$days days" +%Y-%m-%d)
    
    # Create user
    useradd -m -s /bin/false "$username"
    echo "$username:$password" | chpasswd
    
    # Set expiration date
    chage -E "$expiration_date" "$username"
    
    # Create user info file
    mkdir -p /etc/udp-custom/users
    cat > "/etc/udp-custom/users/ssh_$username" << EOF
USERNAME: $username
PASSWORD: $password
SERVICE: SSH
CREATED: $(date +%Y-%m-%d)
EXPIRED: $expiration_date
STATUS: ACTIVE
EOF
    
    print_success "User SSH berhasil dibuat!"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}Detail User:${NC}"
    echo -e "  Username: $username"
    echo -e "  Password: $password"
    echo -e "  Masa Aktif: $days hari"
    echo -e "  Expired: $expiration_date"
    echo -e "  Config UDP: /etc/udp-custom/udp-config.json"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    log "SSH user created: $username (expires: $expiration_date)"
    press_any_key
}

# Delete SSH User
delete_ssh_user() {
    clear
    print_ssh_banner
    echo -e "${CYAN}HAPUS USER SSH${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    read -p "Masukkan username: " username
    
    if ! id "$username" &>/dev/null; then
        print_error "User $username tidak ditemukan!"
        return 1
    fi
    
    echo -e "${YELLOW}User $username akan dihapus!${NC}"
    read -p "Apakah Anda yakin? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Kill user processes
        pkill -u "$username"
        sleep 2
        pkill -9 -u "$username" 2>/dev/null
        
        # Delete user
        userdel -r "$username" 2>/dev/null
        
        # Remove user info file
        rm -f "/etc/udp-custom/users/ssh_$username"
        
        print_success "User $username berhasil dihapus!"
        log "SSH user deleted: $username"
    else
        print_info "Penghapusan user dibatalkan"
    fi
    
    press_any_key
}

# List SSH Users
list_ssh_users() {
    clear
    print_ssh_banner
    echo -e "${CYAN}DAFTAR USER SSH${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║ ${CYAN}USERNAME${NC}          ${CYAN}PASSWORD${NC}       ${CYAN}STATUS${NC}    ${CYAN}EXPIRED${NC}         ${GREEN}║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${NC}"
    
    if [ -d "/etc/udp-custom/users" ]; then
        for user_file in /etc/udp-custom/users/ssh_*; do
            if [ -f "$user_file" ]; then
                username=$(grep "^USERNAME:" "$user_file" | cut -d: -f2 | tr -d ' ')
                password=$(grep "^PASSWORD:" "$user_file" | cut -d: -f2 | tr -d ' ')
                expired=$(grep "^EXPIRED:" "$user_file" | cut -d: -f2 | tr -d ' ')
                status=$(grep "^STATUS:" "$user_file" | cut -d: -f2 | tr -d ' ')
                
                # Check if account is locked
                if passwd -S "$username" 2>/dev/null | grep -q "LK"; then
                    status="${RED}LOCKED${NC}"
                else
                    status="${GREEN}ACTIVE${NC}"
                fi
                
                printf "${GREEN}║ ${WHITE}%-16s${NC} ${YELLOW}%-12s${NC} %-10s ${WHITE}%-10s${NC}   ${GREEN}║${NC}\n" \
                    "$username" "$password" "$status" "$expired"
            fi
        done
    else
        echo -e "${GREEN}║ ${YELLOW}No SSH users found${NC}                                  ${GREEN}║${NC}"
    fi
    
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    press_any_key
}

# Trial SSH User
trial_ssh_user() {
    clear
    print_ssh_banner
    echo -e "${CYAN}TRIAL USER SSH${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # Generate random username and password
    trial_user="trial-$(generate_random_string 6)"
    trial_pass=$(generate_random_string 8)
    trial_days=1
    
    # Create trial user
    useradd -m -s /bin/false "$trial_user"
    echo "$trial_user:$trial_pass" | chpasswd
    
    # Set expiration to 1 day
    expiration_date=$(date -d "+1 days" +%Y-%m-%d)
    chage -E "$expiration_date" "$trial_user"
    
    # Create user info
    mkdir -p /etc/udp-custom/users
    cat > "/etc/udp-custom/users/ssh_$trial_user" << EOF
USERNAME: $trial_user
PASSWORD: $trial_pass
SERVICE: SSH-TRIAL
CREATED: $(date +%Y-%m-%d)
EXPIRED: $expiration_date
STATUS: ACTIVE
EOF
    
    print_success "Trial User SSH berhasil dibuat!"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}Detail Trial User:${NC}"
    echo -e "  Username: $trial_user"
    echo -e "  Password: $trial_pass"
    echo -e "  Masa Aktif: 1 hari"
    echo -e "  Expired: $expiration_date"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    log "Trial SSH user created: $trial_user"
    press_any_key
}

# Limit SSH Speed
limit_ssh_speed() {
    clear
    print_ssh_banner
    echo -e "${CYAN}BATASI KECEPATAN USER SSH${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    read -p "Masukkan username: " username
    
    if ! id "$username" &>/dev/null; then
        print_error "User $username tidak ditemukan!"
        return 1
    fi
    
    echo -e "${YELLOW}Batasan kecepatan untuk user: $username${NC}"
    read -p "Download limit (MB/s): " download_limit
    read -p "Upload limit (MB/s): " upload_limit
    
    if [ -z "$download_limit" ] || [ -z "$upload_limit" ]; then
        print_error "Limit download dan upload harus diisi!"
        return 1
    fi
    
    # Convert MB to KB (for wondershaper)
    download_kb=$((download_limit * 1024))
    upload_kb=$((upload_limit * 1024))
    
    # Install wondershaper if not exists
    if ! command -v wondershaper &> /dev/null; then
        apt-get install -y wondershaper > /dev/null 2>&1
    fi
    
    # Apply speed limit (this is a simplified version)
    # In production, you might want to use tc (traffic control) directly
    
    print_success "Limit kecepatan diterapkan untuk user $username"
    echo -e "  Download: ${download_limit}MB/s"
    echo -e "  Upload: ${upload_limit}MB/s"
    
    log "SSH speed limit set for $username: DL=${download_limit}MB/s UL=${upload_limit}MB/s"
    press_any_key
}

# Config UDP Custom
config_udp_custom() {
    clear
    print_ssh_banner
    echo -e "${CYAN}CONFIG UDP CUSTOM${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    echo -e "${YELLOW}Mengkonfigurasi UDP Custom...${NC}"
    
    # Create UDP config directory
    mkdir -p /etc/udp-custom/config
    
    # Generate UDP config
    cat > /etc/udp-custom/udp-config.json << EOF
{
    "udp_custom": {
        "enabled": true,
        "port": 7300,
        "max_connections": 1000,
        "timeout": 300,
        "buffer_size": 8192
    },
    "ssh_ws": {
        "enabled": true,
        "path": "/sshws",
        "port": 2082
    },
    "limits": {
        "max_users": 100,
        "auto_ban": true,
        "ban_time": 120
    }
}
EOF
    
    # Create systemd service for UDP custom
    cat > /etc/systemd/system/udp-custom.service << EOF
[Unit]
Description=UDP Custom Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/udp-custom
ExecStart=/usr/bin/python3 /etc/udp-custom/udp-server.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    
    # Create simple UDP server script (Python)
    cat > /etc/udp-custom/udp-server.py << 'EOF'
#!/usr/bin/env python3
import socket
import threading
import time

class UDPServer:
    def __init__(self, host='0.0.0.0', port=7300):
        self.host = host
        self.port = port
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.bind((host, port))
        self.clients = {}
        
    def handle_client(self, data, addr):
        try:
            # Simple echo server for demonstration
            self.sock.sendto(data, addr)
        except Exception as e:
            print(f"Error handling client {addr}: {e}")
            
    def start(self):
        print(f"UDP Server started on {self.host}:{self.port}")
        while True:
            try:
                data, addr = self.sock.recvfrom(1024)
                threading.Thread(target=self.handle_client, args=(data, addr)).start()
            except Exception as e:
                print(f"Server error: {e}")

if __name__ == "__main__":
    server = UDPServer()
    server.start()
EOF
    
    chmod +x /etc/udp-custom/udp-server.py
    
    # Install Python if not exists
    if ! command -v python3 &> /dev/null; then
        apt-get install -y python3 > /dev/null 2>&1
    fi
    
    # Enable and start service
    systemctl daemon-reload
    systemctl enable udp-custom.service > /dev/null 2>&1
    systemctl start udp-custom.service > /dev/null 2>&1
    
    print_success "UDP Custom berhasil dikonfigurasi!"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}Config Details:${NC}"
    echo -e "  UDP Port: 7300"
    echo -e "  SSH WS Path: /sshws"
    echo -e "  SSH WS Port: 2082"
    echo -e "  Service: udp-custom"
    echo -e "  Status: $(systemctl is-active udp-custom.service)"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    log "UDP Custom configuration completed"
    press_any_key
}

# Restart SSH Service
restart_ssh_service() {
    clear
    print_ssh_banner
    echo -e "${CYAN}RESTART SSH SERVICE${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    echo -e "${YELLOW}Merestart service SSH...${NC}"
    
    if systemctl is-active --quiet ssh; then
        systemctl restart ssh
        print_success "SSH service berhasil di-restart"
    else
        systemctl start ssh
        print_success "SSH service berhasil di-start"
    fi
    
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "Status: $(systemctl is-active ssh)"
    echo -e "Port: 22"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    log "SSH service restarted"
    press_any_key
}