#!/bin/bash

# Load libraries
source /etc/udp-custom/lib/colors.sh
source /etc/udp-custom/lib/helpers.sh

# User management menu
user_management_menu() {
    while true; do
        clear
        echo -e "${CYAN}"
        cat << "EOF"
  _   _                _    __  __                                   
 | | | |___  ___ _ __ | |_ |  \/  | __ _ _ __   __ _  __ _  ___ _ __ 
 | | | / __|/ _ \ '_ \| __|| |\/| |/ _` | '_ \ / _` |/ _` |/ _ \ '__|
 | |_| \__ \  __/ | | | |_ | |  | | (_| | | | | (_| | (_| |  __/ |   
  \___/|___/\___|_| |_|\__||_|  |_|\__,_|_| |_|\__,_|\__, |\___|_|   
                                                      |___/           
EOF
        echo -e "${NC}"
        
        echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║          ${CYAN}USER MANAGEMENT${GREEN}              ║${NC}"
        echo -e "${GREEN}╠════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║   ${WHITE}1. List All Users${NC}                    ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}2. View User Details${NC}                 ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}3. Delete User${NC}                       ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}4. Lock/Unlock User${NC}                  ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}5. Change User Password${NC}              ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}6. Check User Login${NC}                  ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}7. Auto Ban Multi Login${NC}              ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${RED}0. Back to Main Menu${NC}               ${GREEN}║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
        echo ""
        
        read -p "Pilih menu [0-7]: " choice
        
        case $choice in
            1) list_all_users ;;
            2) view_user_details ;;
            3) delete_user_menu ;;
            4) lock_unlock_user ;;
            5) change_user_password ;;
            6) check_user_login ;;
            7) auto_ban_multi_login ;;
            0) break ;;
            *) 
                print_error "Pilihan tidak valid!"
                sleep 2
                ;;
        esac
    done
}

# List all users
list_all_users() {
    clear
    print_info "Daftar semua pengguna:"
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║ ${CYAN}USERNAME${NC}          ${CYAN}SERVICE${NC}     ${CYAN}STATUS${NC}    ${CYAN}LOGIN${NC}   ${CYAN}EXPIRED${NC}         ${GREEN}║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${NC}"
    
    # SSH Users
    if [ -f "/etc/shadow" ]; then
        while IFS=: read -r username _ uid _ _ _ _ _; do
            if [ "$uid" -ge 1000 ] 2>/dev/null; then
                # Check if user is locked
                if passwd -S "$username" 2>/dev/null | grep -q "LK"; then
                    status="${RED}LOCKED${NC}"
                else
                    status="${GREEN}ACTIVE${NC}"
                fi
                
                # Check current login
                login_count=$(who | grep -c "$username")
                
                # Get expiration date (30 days from creation)
                created_date=$(date -d "$(ls -ld /home/$username 2>/dev/null | awk '{print $6}')" +%s 2>/dev/null)
                if [ -n "$created_date" ]; then
                    expired_date=$((created_date + 2592000)) # 30 days
                    expired_str=$(date -d "@$expired_date" "+%Y-%m-%d")
                else
                    expired_str="UNKNOWN"
                fi
                
                printf "${GREEN}║ ${WHITE}%-16s${NC} ${YELLOW}%-8s${NC} %-10s ${CYAN}%-4s${NC}   ${WHITE}%-10s${NC}   ${GREEN}║${NC}\n" \
                    "$username" "SSH" "$status" "$login_count" "$expired_str"
            fi
        done < /etc/passwd
    fi
    
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    press_any_key
}

# View user details
view_user_details() {
    read -p "Masukkan username: " username
    
    if ! id "$username" &>/dev/null; then
        print_error "User $username tidak ditemukan!"
        return 1
    fi
    
    clear
    print_info "Detail User: $username"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # Basic info
    echo -e "${CYAN}Informasi Dasar:${NC}"
    echo -e "  Username: $username"
    echo -e "  UID: $(id -u $username)"
    echo -e "  GID: $(id -g $username)"
    echo -e "  Home: $(getent passwd $username | cut -d: -f6)"
    echo -e "  Shell: $(getent passwd $username | cut -d: -f7)"
    
    # Account status
    echo -e "\n${CYAN}Status Akun:${NC}"
    local status_info=$(passwd -S "$username" 2>/dev/null)
    if echo "$status_info" | grep -q "LK"; then
        echo -e "  Status: ${RED}TERKUNCI${NC}"
    else
        echo -e "  Status: ${GREEN}AKTIF${NC}"
    fi
    
    # Login information
    echo -e "\n${CYAN}Informasi Login:${NC}"
    local login_count=$(who | grep -c "$username")
    echo -e "  Sedang login: $login_count session(s)"
    
    # Last login
    local last_login=$(last -n 1 "$username" | head -n1 | awk '{print $4" "$5" "$6" "$7}')
    if [ -n "$last_login" ] && [ "$last_login" != "logged" ]; then
        echo -e "  Login terakhir: $last_login"
    else
        echo -e "  Login terakhir: Never"
    fi
    
    # Bandwidth usage (simplified)
    echo -e "\n${CYAN}Penggunaan Bandwidth:${NC}"
    echo -e "  Download: $(du -sh /home/$username 2>/dev/null | awk '{print $1}')"
    
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    press_any_key
}

# Delete user menu
delete_user_menu() {
    read -p "Masukkan username yang akan dihapus: " username
    
    if ! id "$username" &>/dev/null; then
        print_error "User $username tidak ditemukan!"
        return 1
    fi
    
    echo -e "${YELLOW}User $username akan dihapus beserta semua datanya!${NC}"
    read -p "Apakah Anda yakin? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Kill all user processes
        pkill -u "$username"
        sleep 2
        pkill -9 -u "$username" 2>/dev/null
        
        # Delete user and home directory
        userdel -r "$username" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            print_success "User $username berhasil dihapus!"
            log "User deleted: $username"
        else
            print_error "Gagal menghapus user $username"
        fi
    else
        print_info "Penghapusan user dibatalkan"
    fi
    press_any_key
}

# Lock/Unlock user
lock_unlock_user() {
    read -p "Masukkan username: " username
    
    if ! id "$username" &>/dev/null; then
        print_error "User $username tidak ditemukan!"
        return 1
    fi
    
    local status=$(passwd -S "$username" 2>/dev/null | awk '{print $2}')
    
    if [ "$status" = "L" ]; then
        # Unlock user
        passwd -u "$username"
        print_success "User $username berhasil diunlock!"
        log "User unlocked: $username"
    else
        # Lock user
        passwd -l "$username"
        print_success "User $username berhasil dilock!"
        log "User locked: $username"
    fi
    press_any_key
}

# Change user password
change_user_password() {
    read -p "Masukkan username: " username
    
    if ! id "$username" &>/dev/null; then
        print_error "User $username tidak ditemukan!"
        return 1
    fi
    
    echo -e "${YELLOW}Mengubah password untuk user: $username${NC}"
    passwd "$username"
    
    if [ $? -eq 0 ]; then
        print_success "Password berhasil diubah untuk user $username"
        log "Password changed for user: $username"
    fi
    press_any_key
}

# Check user login
check_user_login() {
    clear
    print_info "User yang sedang login:"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    if command -v who &> /dev/null; then
        who | while read -r line; do
            username=$(echo "$line" | awk '{print $1}')
            terminal=$(echo "$line" | awk '{print $2}')
            time=$(echo "$line" | awk '{print $3" "$4}')
            from=$(echo "$line" | awk '{print $5}')
            
            echo -e "  ${CYAN}User:${NC} $username"
            echo -e "  ${CYAN}Terminal:${NC} $terminal"
            echo -e "  ${CYAN}Waktu:${NC} $time"
            echo -e "  ${CYAN}Dari:${NC} $from"
            echo -e "${GREEN}────────────────────────────────${NC}"
        done
    else
        print_error "Command 'who' tidak tersedia"
    fi
    
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    press_any_key
}

# Auto ban multi login
auto_ban_multi_login() {
    clear
    print_info "Auto Ban Multi Login"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    echo -e "${YELLOW}1. Ban user dengan login > 2 session (1 menit)${NC}"
    echo -e "${YELLOW}2. Ban user dengan login > 2 session (2 menit)${NC}"
    echo -e "${YELLOW}3. Lihat daftar banned IP${NC}"
    echo -e "${YELLOW}4. Hapus semua banned IP${NC}"
    echo -e "${RED}0. Kembali${NC}"
    echo ""
    
    read -p "Pilih opsi [0-4]: " choice
    
    case $choice in
        1)
            ban_multi_login_1min
            ;;
        2)
            ban_multi_login_2min
            ;;
        3)
            show_banned_ips
            ;;
        4)
            clear_all_bans
            ;;
        0)
            return
            ;;
        *)
            print_error "Pilihan tidak valid!"
            ;;
    esac
    press_any_key
}

# Ban multi login 1 minute
ban_multi_login_1min() {
    print_info "Memindai multi login (1 menit ban)..."
    
    # Get users with more than 2 logins
    who | awk '{print $1}' | sort | uniq -c | while read count user; do
        if [ "$count" -gt 2 ]; then
            print_warning "User $user memiliki $count session, memban IP..."
            
            # Get IP addresses for this user
            who | grep "^$user " | awk '{print $5}' | sed 's/[()]//g' | while read ip; do
                if validate_ip "$ip"; then
                    # Ban IP for 1 minute
                    iptables -A INPUT -s "$ip" -j DROP
                    (
                        sleep 60
                        iptables -D INPUT -s "$ip" -j DROP 2>/dev/null
                    ) &
                    print_success "IP $ip diban selama 1 menit"
                    log "IP banned for 1min: $ip (user: $user, sessions: $count)"
                fi
            done
        fi
    done
}

# Ban multi login 2 minutes
ban_multi_login_2min() {
    print_info "Memindai multi login (2 menit ban)..."
    
    # Get users with more than 2 logins
    who | awk '{print $1}' | sort | uniq -c | while read count user; do
        if [ "$count" -gt 2 ]; then
            print_warning "User $user memiliki $count session, memban IP..."
            
            # Get IP addresses for this user
            who | grep "^$user " | awk '{print $5}' | sed 's/[()]//g' | while read ip; do
                if validate_ip "$ip"; then
                    # Ban IP for 2 minutes
                    iptables -A INPUT -s "$ip" -j DROP
                    (
                        sleep 120
                        iptables -D INPUT -s "$ip" -j DROP 2>/dev/null
                    ) &
                    print_success "IP $ip diban selama 2 menit"
                    log "IP banned for 2min: $ip (user: $user, sessions: $count)"
                fi
            done
        fi
    done
}

# Show banned IPs
show_banned_ips() {
    print_info "Daftar IP yang sedang diban:"
    iptables -L INPUT -n --line-numbers | grep DROP
}

# Clear all bans
clear_all_bans() {
    print_warning "Menghapus semua banned IP..."
    iptables -L INPUT -n --line-numbers | grep DROP | awk '{print $1}' | tac | while read line; do
        iptables -D INPUT "$line"
    done
    print_success "Semua banned IP telah dihapus"
}

# System info menu
system_info_menu() {
    clear
    print_info "System Information"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # Basic system info
    echo -e "${CYAN}System:${NC}"
    echo -e "  Hostname: $(hostname)"
    echo -e "  OS: $(lsb_release -d | cut -f2)"
    echo -e "  Kernel: $(uname -r)"
    echo -e "  Architecture: $(uname -m)"
    echo -e "  Timezone: $(timedatectl show --property=Timezone --value)"
    echo -e "  Uptime: $(uptime -p | sed 's/up //')"
    
    # CPU info
    echo -e "\n${CYAN}CPU:${NC}"
    echo -e "  Model: $(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
    echo -e "  Cores: $(nproc)"
    echo -e "  Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8"%"}')"
    
    # Memory info
    echo -e "\n${CYAN}Memory:${NC}"
    total_mem=$(free -h | grep Mem | awk '{print $2}')
    used_mem=$(free -h | grep Mem | awk '{print $3}')
    free_mem=$(free -h | grep Mem | awk '{print $4}')
    echo -e "  Total: $total_mem"
    echo -e "  Used: $used_mem"
    echo -e "  Free: $free_mem"
    
    # Disk info
    echo -e "\n${CYAN}Disk:${NC}"
    total_disk=$(df -h / | awk 'NR==2 {print $2}')
    used_disk=$(df -h / | awk 'NR==2 {print $3}')
    free_disk=$(df -h / | awk 'NR==2 {print $4}')
    usage_disk=$(df -h / | awk 'NR==2 {print $5}')
    echo -e "  Total: $total_disk"
    echo -e "  Used: $used_disk ($usage_disk)"
    echo -e "  Free: $free_disk"
    
    # Network info
    echo -e "\n${CYAN}Network:${NC}"
    echo -e "  IP Address: $(get_server_ip)"
    echo -e "  Public IP: $(curl -s ifconfig.me)"
    
    # Service status
    echo -e "\n${CYAN}Services:${NC}"
    services=("nginx" "docker" "cron")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            echo -e "  $service: ${GREEN}ACTIVE${NC}"
        else
            echo -e "  $service: ${RED}INACTIVE${NC}"
        fi
    done
    
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    press_any_key
}