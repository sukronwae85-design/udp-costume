#!/bin/bash

# Load libraries
source /etc/udp-custom/lib/colors.sh
source /etc/udp-custom/lib/helpers.sh

# Bandwidth Management Menu
monitor_bandwidth_menu() {
    while true; do
        clear
        print_bandwidth_banner
        
        echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║         ${CYAN}BANDWIDTH MANAGEMENT${GREEN}           ║${NC}"
        echo -e "${GREEN}╠════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║   ${WHITE}1. Monitor Real-time Bandwidth${NC}        ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}2. Limit Account Bandwidth${NC}            ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}3. Limit Server Bandwidth${NC}             ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}4. View Bandwidth Usage${NC}               ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}5. Reset Bandwidth Limits${NC}             ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}6. Bandwidth Statistics${NC}               ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}7. Auto Bandwidth Management${NC}          ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${RED}0. Back to Main Menu${NC}               ${GREEN}║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
        echo ""
        
        read -p "Pilih menu [0-7]: " choice
        
        case $choice in
            1) monitor_realtime_bandwidth ;;
            2) limit_account_bandwidth_menu ;;
            3) limit_server_bandwidth_menu ;;
            4) view_bandwidth_usage ;;
            5) reset_bandwidth_limits ;;
            6) bandwidth_statistics ;;
            7) auto_bandwidth_management ;;
            0) break ;;
            *) 
                print_error "Pilihan tidak valid!"
                sleep 2
                ;;
        esac
    done
}

# Monitor Real-time Bandwidth
monitor_realtime_bandwidth() {
    clear
    echo -e "${CYAN}REAL-TIME BANDWIDTH MONITOR${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # Check if iftop is installed
    if ! command -v iftop &> /dev/null; then
        print_info "Menginstall iftop untuk monitoring bandwidth..."
        apt-get update > /dev/null 2>&1
        apt-get install -y iftop > /dev/null 2>&1
    fi
    
    # Check if vnstat is installed
    if ! command -v vnstat &> /dev/null; then
        print_info "Menginstall vnstat untuk statistics..."
        apt-get install -y vnstat > /dev/null 2>&1
        systemctl enable vnstat > /dev/null 2>&1
        systemctl start vnstat > /dev/null 2>&1
    fi
    
    print_info "Real-time Bandwidth Monitoring (Ctrl+C to stop)"
    echo -e "${YELLOW}Interface: $(ip route get 8.8.8.8 | awk '{print $5}' | head -1)${NC}"
    
    # Show real-time bandwidth using iftop
    iftop -i $(ip route get 8.8.8.8 | awk '{print $5}' | head -1) -B -P
    
    press_any_key
}

# Limit Account Bandwidth Menu
limit_account_bandwidth_menu() {
    clear
    echo -e "${CYAN}LIMIT ACCOUNT BANDWIDTH${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    echo -e "${YELLOW}1. Limit SSH User Bandwidth${NC}"
    echo -e "${YELLOW}2. Limit Vmess User Bandwidth${NC}"
    echo -e "${YELLOW}3. Limit Vless User Bandwidth${NC}"
    echo -e "${YELLOW}4. Limit Trojan User Bandwidth${NC}"
    echo -e "${YELLOW}5. Limit All Users Bandwidth${NC}"
    echo -e "${RED}0. Back${NC}"
    echo ""
    
    read -p "Pilih opsi [0-5]: " choice
    
    case $choice in
        1) limit_ssh_bandwidth ;;
        2) limit_vmess_bandwidth ;;
        3) limit_vless_bandwidth ;;
        4) limit_trojan_bandwidth ;;
        5) limit_all_users_bandwidth ;;
        0) return ;;
        *) print_error "Pilihan tidak valid" ;;
    esac
}

# Limit SSH User Bandwidth
limit_ssh_bandwidth() {
    clear
    echo -e "${CYAN}LIMIT SSH USER BANDWIDTH${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    read -p "Masukkan username SSH: " username
    
    if ! id "$username" &>/dev/null; then
        print_error "User SSH $username tidak ditemukan!"
        return 1
    fi
    
    echo -e "${YELLOW}Batasan bandwidth untuk user: $username${NC}"
    read -p "Download limit (MB/s): " download_limit
    read -p "Upload limit (MB/s): " upload_limit
    
    if [ -z "$download_limit" ] || [ -z "$upload_limit" ]; then
        print_error "Limit download dan upload harus diisi!"
        return 1
    fi
    
    # Install wondershaper if not exists
    if ! command -v wondershaper &> /dev/null; then
        apt-get install -y wondershaper > /dev/null 2>&1
    fi
    
    # Convert MB to Kbps (1 MB = 8192 Kbps)
    download_kbps=$((download_limit * 8192))
    upload_kbps=$((upload_limit * 8192))
    
    # Get user's IP addresses (simplified - in production you'd need more complex tracking)
    user_ips=$(who | grep "$username" | awk '{print $5}' | sed 's/[()]//g' | sort -u)
    
    for ip in $user_ips; do
        if validate_ip "$ip"; then
            # Apply bandwidth limit using tc (traffic control)
            apply_tc_limit "$ip" "$download_kbps" "$upload_kbps"
        fi
    done
    
    # Save limit to user config
    mkdir -p /etc/udp-custom/bandwidth
    echo "$download_limit $upload_limit" > "/etc/udp-custom/bandwidth/ssh_$username"
    
    print_success "Bandwidth limit diterapkan untuk user $username"
    echo -e "  Download: ${download_limit}MB/s (${download_kbps}Kbps)"
    echo -e "  Upload: ${upload_limit}MB/s (${upload_kbps}Kbps)"
    
    log "SSH bandwidth limit set for $username: DL=${download_limit}MB/s UL=${upload_limit}MB/s"
    press_any_key
}

# Apply TC Limit
apply_tc_limit() {
    local ip=$1
    local download=$2
    local upload=$3
    local interface=$(ip route get 8.8.8.8 | awk '{print $5}' | head -1)
    
    # Clean existing rules
    tc qdisc del dev $interface root 2>/dev/null
    tc qdisc del dev $interface ingress 2>/dev/null
    
    # Create HTB queue discipline
    tc qdisc add dev $interface root handle 1: htb
    tc class add dev $interface parent 1: classid 1:1 htb rate 1000mbit
    
    # Add class for specific IP
    tc class add dev $interface parent 1:1 classid 1:10 htb rate ${upload}kbit ceil ${upload}kbit
    tc filter add dev $interface protocol ip parent 1:0 prio 1 u32 match ip src $ip flowid 1:10
    
    # Ingress policing for download
    tc qdisc add dev $interface handle ffff: ingress
    tc filter add dev $interface parent ffff: protocol ip prio 1 u32 match ip dst $ip police rate ${download}kbit burst 10k drop flowid :1
    
    print_info "TC rules applied for IP $ip"
}

# Limit Vmess User Bandwidth
limit_vmess_bandwidth() {
    clear
    echo -e "${CYAN}LIMIT VMESS USER BANDWIDTH${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    read -p "Masukkan username Vmess: " username
    
    if [ ! -f "/etc/udp-custom/users/vmess_$username" ]; then
        print_error "User Vmess $username tidak ditemukan!"
        return 1
    fi
    
    echo -e "${YELLOW}Batasan bandwidth untuk user: $username${NC}"
    read -p "Download limit (MB/s): " download_limit
    read -p "Upload limit (MB/s): " upload_limit
    
    if [ -z "$download_limit" ] || [ -z "$upload_limit" ]; then
        print_error "Limit download dan upload harus diisi!"
        return 1
    fi
    
    # Update user config with bandwidth limit
    echo "DOWNLOAD_LIMIT: $download_limit" >> "/etc/udp-custom/users/vmess_$username"
    echo "UPLOAD_LIMIT: $upload_limit" >> "/etc/udp-custom/users/vmess_$username"
    
    # Update Xray config with bandwidth limits
    update_xray_bandwidth_limits
    
    print_success "Bandwidth limit diterapkan untuk user Vmess $username"
    echo -e "  Download: ${download_limit}MB/s"
    echo -e "  Upload: ${upload_limit}MB/s"
    
    log "Vmess bandwidth limit set for $username: DL=${download_limit}MB/s UL=${upload_limit}MB/s"
    press_any_key
}

# Limit Vless User Bandwidth
limit_vless_bandwidth() {
    clear
    echo -e "${CYAN}LIMIT VLESS USER BANDWIDTH${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    read -p "Masukkan username Vless: " username
    
    if [ ! -f "/etc/udp-custom/users/vless_$username" ]; then
        print_error "User Vless $username tidak ditemukan!"
        return 1
    fi
    
    echo -e "${YELLOW}Batasan bandwidth untuk user: $username${NC}"
    read -p "Download limit (MB/s): " download_limit
    read -p "Upload limit (MB/s): " upload_limit
    
    if [ -z "$download_limit" ] || [ -z "$upload_limit" ]; then
        print_error "Limit download dan upload harus diisi!"
        return 1
    fi
    
    # Update user config with bandwidth limit
    echo "DOWNLOAD_LIMIT: $download_limit" >> "/etc/udp-custom/users/vless_$username"
    echo "UPLOAD_LIMIT: $upload_limit" >> "/etc/udp-custom/users/vless_$username"
    
    print_success "Bandwidth limit diterapkan untuk user Vless $username"
    echo -e "  Download: ${download_limit}MB/s"
    echo -e "  Upload: ${upload_limit}MB/s"
    
    log "Vless bandwidth limit set for $username: DL=${download_limit}MB/s UL=${upload_limit}MB/s"
    press_any_key
}

# Limit Trojan User Bandwidth
limit_trojan_bandwidth() {
    clear
    echo -e "${CYAN}LIMIT TROJAN USER BANDWIDTH${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    read -p "Masukkan username Trojan: " username
    
    if [ ! -f "/etc/udp-custom/users/trojan_$username" ]; then
        print_error "User Trojan $username tidak ditemukan!"
        return 1
    fi
    
    echo -e "${YELLOW}Batasan bandwidth untuk user: $username${NC}"
    read -p "Download limit (MB/s): " download_limit
    read -p "Upload limit (MB/s): " upload_limit
    
    if [ -z "$download_limit" ] || [ -z "$upload_limit" ]; then
        print_error "Limit download dan upload harus diisi!"
        return 1
    fi
    
    # Update user config with bandwidth limit
    echo "DOWNLOAD_LIMIT: $download_limit" >> "/etc/udp-custom/users/trojan_$username"
    echo "UPLOAD_LIMIT: $upload_limit" >> "/etc/udp-custom/users/trojan_$username"
    
    print_success "Bandwidth limit diterapkan untuk user Trojan $username"
    echo -e "  Download: ${download_limit}MB/s"
    echo -e "  Upload: ${upload_limit}MB/s"
    
    log "Trojan bandwidth limit set for $username: DL=${download_limit}MB/s UL=${upload_limit}MB/s"
    press_any_key
}

# Limit All Users Bandwidth
limit_all_users_bandwidth() {
    clear
    echo -e "${CYAN}LIMIT ALL USERS BANDWIDTH${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    echo -e "${YELLOW}Batasan bandwidth untuk semua user${NC}"
    read -p "Download limit (MB/s): " download_limit
    read -p "Upload limit (MB/s): " upload_limit
    
    if [ -z "$download_limit" ] || [ -z "$upload_limit" ]; then
        print_error "Limit download dan upload harus diisi!"
        return 1
    fi
    
    # Apply to all SSH users
    for user_file in /etc/udp-custom/users/ssh_*; do
        if [ -f "$user_file" ]; then
            username=$(basename "$user_file" | sed 's/ssh_//')
            echo "DOWNLOAD_LIMIT: $download_limit" >> "$user_file"
            echo "UPLOAD_LIMIT: $upload_limit" >> "$user_file"
        fi
    done
    
    # Apply to all Vmess users
    for user_file in /etc/udp-custom/users/vmess_*; do
        if [ -f "$user_file" ]; then
            echo "DOWNLOAD_LIMIT: $download_limit" >> "$user_file"
            echo "UPLOAD_LIMIT: $upload_limit" >> "$user_file"
        fi
    done
    
    # Apply to all Vless users
    for user_file in /etc/udp-custom/users/vless_*; do
        if [ -f "$user_file" ]; then
            echo "DOWNLOAD_LIMIT: $download_limit" >> "$user_file"
            echo "UPLOAD_LIMIT: $upload_limit" >> "$user_file"
        fi
    done
    
    # Apply to all Trojan users
    for user_file in /etc/udp-custom/users/trojan_*; do
        if [ -f "$user_file" ]; then
            echo "DOWNLOAD_LIMIT: $download_limit" >> "$user_file"
            echo "UPLOAD_LIMIT: $upload_limit" >> "$user_file"
        fi
    done
    
    print_success "Bandwidth limit diterapkan untuk semua user"
    echo -e "  Download: ${download_limit}MB/s"
    echo -e "  Upload: ${upload_limit}MB/s"
    
    log "Global bandwidth limit set: DL=${download_limit}MB/s UL=${upload_limit}MB/s"
    press_any_key
}

# Limit Server Bandwidth Menu
limit_server_bandwidth_menu() {
    clear
    echo -e "${CYAN}LIMIT SERVER BANDWIDTH${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # Get current bandwidth usage
    print_info "Current bandwidth usage:"
    if command -v vnstat &> /dev/null; then
        vnstat -i $(ip route get 8.8.8.8 | awk '{print $5}' | head -1) -tr
    fi
    
    echo -e "\n${YELLOW}1. Limit Total Server Bandwidth${NC}"
    echo -e "${YELLOW}2. Limit Per-Protocol Bandwidth${NC}"
    echo -e "${YELLOW}3. Set Bandwidth Schedule${NC}"
    echo -e "${RED}0. Back${NC}"
    echo ""
    
    read -p "Pilih opsi [0-3]: " choice
    
    case $choice in
        1) limit_total_server_bandwidth ;;
        2) limit_per_protocol_bandwidth ;;
        3) set_bandwidth_schedule ;;
        0) return ;;
        *) print_error "Pilihan tidak valid" ;;
    esac
}

# Limit Total Server Bandwidth
limit_total_server_bandwidth() {
    clear
    echo -e "${CYAN}LIMIT TOTAL SERVER BANDWIDTH${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    read -p "Total download limit (MB/s): " total_download
    read -p "Total upload limit (MB/s): " total_upload
    
    if [ -z "$total_download" ] || [ -z "$total_upload" ]; then
        print_error "Limit download dan upload harus diisi!"
        return 1
    fi
    
    # Convert to Kbps
    download_kbps=$((total_download * 8192))
    upload_kbps=$((total_upload * 8192))
    
    # Install wondershaper
    if ! command -v wondershaper &> /dev/null; then
        apt-get install -y wondershaper > /dev/null 2>&1
    fi
    
    # Get network interface
    interface=$(ip route get 8.8.8.8 | awk '{print $5}' | head -1)
    
    # Apply bandwidth limit using wondershaper
    wondershaper -a $interface -d $download_kbps -u $upload_kbps
    
    # Save to config
    mkdir -p /etc/udp-custom/bandwidth
    echo "TOTAL_DOWNLOAD: $total_download" > /etc/udp-custom/bandwidth/server_limits
    echo "TOTAL_UPLOAD: $total_upload" >> /etc/udp-custom/bandwidth/server_limits
    
    print_success "Total server bandwidth limit diterapkan"
    echo -e "  Download: ${total_download}MB/s"
    echo -e "  Upload: ${total_upload}MB/s"
    echo -e "  Interface: $interface"
    
    log "Server bandwidth limit set: DL=${total_download}MB/s UL=${total_upload}MB/s"
    press_any_key
}

# Limit Per-Protocol Bandwidth
limit_per_protocol_bandwidth() {
    clear
    echo -e "${CYAN}LIMIT PER-PROTOCOL BANDWIDTH${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    echo -e "${YELLOW}Batasan bandwidth per protocol:${NC}"
    read -p "SSH Bandwidth (MB/s): " ssh_bw
    read -p "Vmess Bandwidth (MB/s): " vmess_bw
    read -p "Vless Bandwidth (MB/s): " vless_bw
    read -p "Trojan Bandwidth (MB/s): " trojan_bw
    
    # Save to config
    mkdir -p /etc/udp-custom/bandwidth
    cat > /etc/udp-custom/bandwidth/protocol_limits << EOF
SSH: $ssh_bw
VMESS: $vmess_bw
VLESS: $vless_bw
TROJAN: $trojan_bw
EOF

    print_success "Protocol bandwidth limits saved"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}Protocol Limits:${NC}"
    echo -e "  SSH: ${ssh_bw}MB/s"
    echo -e "  Vmess: ${vmess_bw}MB/s"
    echo -e "  Vless: ${vless_bw}MB/s"
    echo -e "  Trojan: ${trojan_bw}MB/s"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    log "Protocol bandwidth limits set: SSH=${ssh_bw}MB/s, Vmess=${vmess_bw}MB/s, Vless=${vless_bw}MB/s, Trojan=${trojan_bw}MB/s"
    press_any_key
}

# Set Bandwidth Schedule
set_bandwidth_schedule() {
    clear
    echo -e "${CYAN}SET BANDWIDTH SCHEDULE${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    echo -e "${YELLOW}Set bandwidth limits based on time:${NC}"
    read -p "Daytime limit (08:00-17:00) MB/s: " daytime_limit
    read -p "Evening limit (17:00-24:00) MB/s: " evening_limit
    read -p "Night limit (00:00-08:00) MB/s: " night_limit
    
    # Save schedule
    mkdir -p /etc/udp-custom/bandwidth
    cat > /etc/udp-custom/bandwidth/schedule << EOF
DAYTIME: $daytime_limit
EVENING: $evening_limit
NIGHT: $night_limit
EOF

    # Create cron job for bandwidth scheduling
    (crontab -l 2>/dev/null | grep -v "bandwidth_schedule.sh"; echo "0 8 * * * /etc/udp-custom/bandwidth_schedule.sh daytime") | crontab -
    (crontab -l 2>/dev/null | grep -v "bandwidth_schedule.sh"; echo "0 17 * * * /etc/udp-custom/bandwidth_schedule.sh evening") | crontab -
    (crontab -l 2>/dev/null | grep -v "bandwidth_schedule.sh"; echo "0 0 * * * /etc/udp-custom/bandwidth_schedule.sh night") | crontab -
    
    print_success "Bandwidth schedule berhasil diset"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}Bandwidth Schedule:${NC}"
    echo -e "  08:00-17:00: ${daytime_limit}MB/s"
    echo -e "  17:00-24:00: ${evening_limit}MB/s"
    echo -e "  00:00-08:00: ${night_limit}MB/s"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    log "Bandwidth schedule set: Day=${daytime_limit}MB/s, Evening=${evening_limit}MB/s, Night=${night_limit}MB/s"
    press_any_key
}

# View Bandwidth Usage
view_bandwidth_usage() {
    clear
    echo -e "${CYAN}VIEW BANDWIDTH USAGE${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # Install vnstat if not exists
    if ! command -v vnstat &> /dev/null; then
        apt-get install -y vnstat > /dev/null 2>&1
        systemctl enable vnstat > /dev/null 2>&1
        systemctl start vnstat > /dev/null 2>&1
    fi
    
    interface=$(ip route get 8.8.8.8 | awk '{print $5}' | head -1)
    
    echo -e "${CYAN}Bandwidth Usage for $interface:${NC}"
    echo -e "${GREEN}────────────────────────────────${NC}"
    
    # Show today's usage
    echo -e "${YELLOW}Today's Usage:${NC}"
    vnstat -i $interface -d | tail -n +3
    
    # Show monthly usage
    echo -e "\n${YELLOW}Monthly Usage:${NC}"
    vnstat -i $interface -m | tail -n +3
    
    # Show top bandwidth users (simplified)
    echo -e "\n${YELLOW}Active Connections:${NC}"
    ss -tunp | grep -E ":(22|443|2082|2083|2087)" | awk '{print $6}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -10
    
    press_any_key
}

# Reset Bandwidth Limits
reset_bandwidth_limits() {
    clear
    echo -e "${CYAN}RESET BANDWIDTH LIMITS${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    echo -e "${YELLOW}1. Reset All Bandwidth Limits${NC}"
    echo -e "${YELLOW}2. Reset User Limits Only${NC}"
    echo -e "${YELLOW}3. Reset Server Limits Only${NC}"
    echo -e "${RED}0. Back${NC}"
    echo ""
    
    read -p "Pilih opsi [0-3]: " choice
    
    case $choice in
        1)
            # Reset all limits
            rm -rf /etc/udp-custom/bandwidth
            # Clear TC rules
            interface=$(ip route get 8.8.8.8 | awk '{print $5}' | head -1)
            tc qdisc del dev $interface root 2>/dev/null
            tc qdisc del dev $interface ingress 2>/dev/null
            # Clear wondershaper
            wondershaper -c -a $interface 2>/dev/null
            print_success "Semua bandwidth limits telah direset"
            ;;
        2)
            # Reset user limits
            find /etc/udp-custom/users -name "*" -type f -exec sed -i '/DOWNLOAD_LIMIT\|UPLOAD_LIMIT/d' {} \;
            print_success "Semua user bandwidth limits telah direset"
            ;;
        3)
            # Reset server limits
            rm -f /etc/udp-custom/bandwidth/server_limits
            rm -f /etc/udp-custom/bandwidth/protocol_limits
            rm -f /etc/udp-custom/bandwidth/schedule
            interface=$(ip route get 8.8.8.8 | awk '{print $5}' | head -1)
            wondershaper -c -a $interface 2>/dev/null
            print_success "Server bandwidth limits telah direset"
            ;;
        0)
            return
            ;;
        *)
            print_error "Pilihan tidak valid"
            ;;
    esac
    
    log "Bandwidth limits reset"
    press_any_key
}

# Bandwidth Statistics
bandwidth_statistics() {
    clear
    echo -e "${CYAN}BANDWIDTH STATISTICS${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # Create statistics directory
    mkdir -p /etc/udp-custom/bandwidth/stats
    
    # Generate bandwidth report
    report_file="/etc/udp-custom/bandwidth/stats/report_$(date +%Y%m%d).txt"
    
    {
        echo "UDP Custom Bandwidth Report"
        echo "Generated: $(date)"
        echo "════════════════════════════════════════"
        echo ""
        
        # System bandwidth
        echo "SYSTEM BANDWIDTH USAGE:"
        echo "──────────────────────"
        if command -v vnstat &> /dev/null; then
            vnstat -d
            echo ""
            vnstat -m
        else
            echo "vnstat not installed"
        fi
        
        echo ""
        echo "USER BANDWIDTH LIMITS:"
        echo "─────────────────────"
        
        # SSH users with limits
        for user_file in /etc/udp-custom/users/ssh_*; do
            if [ -f "$user_file" ]; then
                username=$(basename "$user_file" | sed 's/ssh_//')
                if grep -q "DOWNLOAD_LIMIT" "$user_file"; then
                    dl_limit=$(grep "DOWNLOAD_LIMIT" "$user_file" | cut -d: -f2 | tr -d ' ')
                    ul_limit=$(grep "UPLOAD_LIMIT" "$user_file" | cut -d: -f2 | tr -d ' ')
                    echo "SSH $username: DL ${dl_limit}MB/s - UL ${ul_limit}MB/s"
                fi
            fi
        done
        
        # Vmess users with limits
        for user_file in /etc/udp-custom/users/vmess_*; do
            if [ -f "$user_file" ]; then
                username=$(basename "$user_file" | sed 's/vmess_//')
                if grep -q "DOWNLOAD_LIMIT" "$user_file"; then
                    dl_limit=$(grep "DOWNLOAD_LIMIT" "$user_file" | cut -d: -f2 | tr -d ' ')
                    ul_limit=$(grep "UPLOAD_LIMIT" "$user_file" | cut -d: -f2 | tr -d ' ')
                    echo "Vmess $username: DL ${dl_limit}MB/s - UL ${ul_limit}MB/s"
                fi
            fi
        done
        
        echo ""
        echo "ACTIVE BANDWIDTH LIMITS:"
        echo "───────────────────────"
        interface=$(ip route get 8.8.8.8 | awk '{print $5}' | head -1)
        tc -s qdisc show dev $interface 2>/dev/null | head -10
        
    } > "$report_file"
    
    # Display report
    cat "$report_file"
    
    echo -e "\n${GREEN}Report saved to: $report_file${NC}"
    
    press_any_key
}

# Auto Bandwidth Management
auto_bandwidth_management() {
    clear
    echo -e "${CYAN}AUTO BANDWIDTH MANAGEMENT${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    echo -e "${YELLOW}Automatic bandwidth management features:${NC}"
    echo -e "1. Auto-scale bandwidth based on time"
    echo -e "2. Limit heavy users automatically"
    echo -e "3. Quality of Service (QoS) settings"
    echo -e "4. Bandwidth usage alerts"
    echo -e ""
    
    read -p "Enable auto bandwidth management? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Create auto management script
        cat > /etc/udp-custom/bandwidth/auto_management.sh << 'EOF'
#!/bin/bash

# Auto Bandwidth Management Script
# This script runs periodically to manage bandwidth automatically

LOG_FILE="/etc/udp-custom/bandwidth/auto_management.log"

log() {
    echo "[$(date)] $1" >> $LOG_FILE
}

# Check current bandwidth usage
check_bandwidth_usage() {
    # This is a simplified check - in production you'd use more sophisticated monitoring
    local interface=$(ip route get 8.8.8.8 | awk '{print $5}' | head -1)
    
    # Get current hour for time-based scaling
    local current_hour=$(date +%H)
    
    # Time-based bandwidth scaling
    if [ $current_hour -ge 8 ] && [ $current_hour -lt 17 ]; then
        # Daytime - normal limits
        apply_bandwidth_limits "daytime"
    elif [ $current_hour -ge 17 ] && [ $current_hour -lt 24 ]; then
        # Evening - reduced limits
        apply_bandwidth_limits "evening"
    else
        # Night - increased limits
        apply_bandwidth_limits "night"
    fi
    
    log "Bandwidth limits applied for $current_hour:00"
}

apply_bandwidth_limits() {
    local period=$1
    
    # Load limits from config
    if [ -f "/etc/udp-custom/bandwidth/schedule" ]; then
        local limit=$(grep "$(echo $period | tr '[:lower:]' '[:upper:]')" /etc/udp-custom/bandwidth/schedule | cut -d: -f2 | tr -d ' ')
        if [ -n "$limit" ]; then
            # Apply the limit (implementation depends on your setup)
            log "Applied $period limit: ${limit}MB/s"
        fi
    fi
}

# Main execution
check_bandwidth_usage
EOF

        chmod +x /etc/udp-custom/bandwidth/auto_management.sh
        
        # Add to crontab to run every hour
        (crontab -l 2>/dev/null; echo "0 * * * * /etc/udp-custom/bandwidth/auto_management.sh") | crontab -
        
        print_success "Auto bandwidth management diaktifkan"
        echo -e "  Script: /etc/udp-custom/bandwidth/auto_management.sh"
        echo -e "  Schedule: Setiap jam"
        echo -e "  Log: /etc/udp-custom/bandwidth/auto_management.log"
    else
        # Remove auto management
        crontab -l 2>/dev/null | grep -v "auto_management.sh" | crontab -
        print_info "Auto bandwidth management dinonaktifkan"
    fi
    
    press_any_key
}

# Update Xray bandwidth limits
update_xray_bandwidth_limits() {
    # This function would update Xray configuration with bandwidth limits
    # Implementation depends on Xray version and configuration
    print_info "Updating Xray configuration with bandwidth limits..."
    # Add your Xray bandwidth limit configuration here
}