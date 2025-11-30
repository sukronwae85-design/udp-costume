#!/bin/bash

# Load libraries
source /etc/udp-custom/lib/colors.sh
source /etc/udp-custom/lib/helpers.sh

# Backup Management Menu
backup_menu() {
    while true; do
        clear
        print_backup_banner
        
        echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║           ${CYAN}BACKUP MANAGEMENT${GREEN}             ║${NC}"
        echo -e "${GREEN}╠════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║   ${WHITE}1. Auto Backup Setup${NC}                  ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}2. Manual Backup Now${NC}                  ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}3. Restore Backup${NC}                     ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}4. Configure Gmail Backup${NC}             ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}5. Configure WhatsApp Backup${NC}          ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}6. Configure Telegram Backup${NC}          ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}7. View Backup Logs${NC}                   ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}8. Backup Schedule${NC}                    ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${RED}0. Back to Main Menu${NC}               ${GREEN}║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
        echo ""
        
        read -p "Pilih menu [0-8]: " choice
        
        case $choice in
            1) auto_backup_setup ;;
            2) manual_backup_now ;;
            3) restore_backup ;;
            4) configure_gmail_backup ;;
            5) configure_whatsapp_backup ;;
            6) configure_telegram_backup ;;
            7) view_backup_logs ;;
            8) backup_schedule ;;
            0) break ;;
            *) 
                print_error "Pilihan tidak valid!"
                sleep 2
                ;;
        esac
    done
}

# Auto Backup Setup
auto_backup_setup() {
    clear
    echo -e "${CYAN}AUTO BACKUP SETUP${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    print_info "Menyiapkan auto backup system..."
    
    # Create backup directory
    mkdir -p /etc/udp-custom/backup/{daily,weekly,monthly}
    mkdir -p /etc/udp-custom/backup/logs
    
    # Create backup script
    cat > /etc/udp-custom/backup/auto_backup.sh << 'EOF'
#!/bin/bash

# Auto Backup Script for UDP Custom
# This script runs automatically via cron

# Load colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BACKUP_DIR="/etc/udp-custom/backup"
LOG_FILE="$BACKUP_DIR/logs/backup_$(date +%Y%m%d).log"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Log function
log() {
    echo "[$TIMESTAMP] $1" >> $LOG_FILE
}

# Backup function
perform_backup() {
    local backup_type=$1
    local backup_file="$BACKUP_DIR/${backup_type}/backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    log "Starting $backup_type backup..."
    
    # Create backup
    tar -czf "$backup_file" \
        /etc/udp-custom/users \
        /etc/udp-custom/config \
        /etc/nginx/conf.d \
        /etc/nginx/sites-available \
        /usr/local/etc/xray \
        /etc/trojan \
        /etc/ssl/udp-custom 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log "Backup completed: $backup_file"
        echo -e "${GREEN}Backup completed: $(basename $backup_file)${NC}"
        
        # Remove old backups (keep last 30 days)
        find "$BACKUP_DIR/${backup_type}" -name "*.tar.gz" -mtime +30 -delete
        
        # Send notifications
        send_backup_notifications "$backup_type" "$backup_file"
    else
        log "Backup failed"
        echo -e "${RED}Backup failed${NC}"
    fi
}

# Send notifications
send_backup_notifications() {
    local backup_type=$1
    local backup_file=$2
    
    # Load configuration
    if [ -f /etc/udp-custom/config/config.json ]; then
        # Gmail notification
        if [ "$(jq -r '.backup.gmail.enabled' /etc/udp-custom/config/config.json)" = "true" ]; then
            send_gmail_notification "$backup_type" "$backup_file"
        fi
        
        # Telegram notification
        if [ "$(jq -r '.backup.telegram.enabled' /etc/udp-custom/config/config.json)" = "true" ]; then
            send_telegram_notification "$backup_type" "$backup_file"
        fi
        
        # WhatsApp notification (simulated)
        if [ "$(jq -r '.backup.whatsapp.enabled' /etc/udp-custom/config/config.json)" = "true" ]; then
            send_whatsapp_notification "$backup_type" "$backup_file"
        fi
    fi
}

# Notification functions (implement based on your setup)
send_gmail_notification() {
    local backup_type=$1
    local backup_file=$2
    log "Gmail notification sent for $backup_type backup"
}

send_telegram_notification() {
    local backup_type=$1
    local backup_file=$2
    log "Telegram notification sent for $backup_type backup"
}

send_whatsapp_notification() {
    local backup_type=$1
    local backup_file=$2
    log "WhatsApp notification sent for $backup_type backup"
}

# Main execution
case $1 in
    "daily")
        perform_backup "daily"
        ;;
    "weekly")
        perform_backup "weekly"
        ;;
    "monthly")
        perform_backup "monthly"
        ;;
    *)
        echo "Usage: $0 {daily|weekly|monthly}"
        exit 1
        ;;
esac
EOF

    chmod +x /etc/udp-custom/backup/auto_backup.sh
    
    # Setup cron jobs
    setup_backup_cron
    
    print_success "Auto backup system berhasil disiapkan"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}Backup Configuration:${NC}"
    echo -e "  Backup Directory: /etc/udp-custom/backup"
    echo -e "  Daily Backups: Enabled (2:00 AM)"
    echo -e "  Weekly Backups: Enabled (Sunday 3:00 AM)"
    echo -e "  Monthly Backups: Enabled (1st 4:00 AM)"
    echo -e "  Retention: 30 days"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    log "Auto backup system setup completed"
    press_any_key
}

# Setup Backup Cron Jobs
setup_backup_cron() {
    # Remove existing backup cron jobs
    crontab -l | grep -v "auto_backup.sh" | crontab -
    
    # Add new cron jobs
    (crontab -l 2>/dev/null; echo "0 2 * * * /etc/udp-custom/backup/auto_backup.sh daily") | crontab -
    (crontab -l 2>/dev/null; echo "0 3 * * 0 /etc/udp-custom/backup/auto_backup.sh weekly") | crontab -
    (crontab -l 2>/dev/null; echo "0 4 1 * * /etc/udp-custom/backup/auto_backup.sh monthly") | crontab -
    
    print_success "Cron jobs untuk backup berhasil disetup"
}

# Manual Backup Now
manual_backup_now() {
    clear
    echo -e "${CYAN}MANUAL BACKUP NOW${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    echo -e "${YELLOW}1. Full System Backup${NC}"
    echo -e "${YELLOW}2. Config Files Only${NC}"
    echo -e "${YELLOW}3. User Data Only${NC}"
    echo -e "${RED}0. Back${NC}"
    echo ""
    
    read -p "Pilih tipe backup [0-3]: " choice
    
    case $choice in
        1)
            backup_type="full"
            ;;
        2)
            backup_type="config"
            ;;
        3)
            backup_type="users"
            ;;
        0)
            return
            ;;
        *)
            print_error "Pilihan tidak valid!"
            return 1
            ;;
    esac
    
    print_info "Memulai backup manual ($backup_type)..."
    
    # Create backup filename
    backup_file="/etc/udp-custom/backup/manual_${backup_type}_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    # Perform backup based on type
    case $backup_type in
        "full")
            tar -czf "$backup_file" \
                /etc/udp-custom \
                /etc/nginx \
                /usr/local/etc/xray \
                /etc/trojan \
                /etc/ssl/udp-custom \
                /root/udp-install.log 2>/dev/null
            ;;
        "config")
            tar -czf "$backup_file" \
                /etc/udp-custom/config \
                /etc/nginx/conf.d \
                /etc/nginx/sites-available \
                /usr/local/etc/xray \
                /etc/trojan 2>/dev/null
            ;;
        "users")
            tar -czf "$backup_file" /etc/udp-custom/users 2>/dev/null
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        print_success "Backup manual berhasil dibuat"
        echo -e "${GREEN}════════════════════════════════════════${NC}"
        echo -e "${CYAN}Backup Details:${NC}"
        echo -e "  File: $(basename $backup_file)"
        echo -e "  Size: $(du -h "$backup_file" | cut -f1)"
        echo -e "  Type: $backup_type"
        echo -e "  Location: $backup_file"
        echo -e "${GREEN}════════════════════════════════════════${NC}"
        
        # Send notifications
        send_backup_notification_manual "$backup_type" "$backup_file"
    else
        print_error "Backup manual gagal"
    fi
    
    log "Manual backup created: $backup_file (type: $backup_type)"
    press_any_key
}

# Send manual backup notification
send_backup_notification_manual() {
    local backup_type=$1
    local backup_file=$2
    
    print_info "Mengirim notifikasi backup..."
    
    # This is where you would integrate with actual notification services
    # For now, we'll just log it
    log "Manual backup notification: $backup_type - $backup_file"
}

# Restore Backup
restore_backup() {
    clear
    echo -e "${CYAN}RESTORE BACKUP${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # List available backups
    print_info "Available backups:"
    find /etc/udp-custom/backup -name "*.tar.gz" -type f | sort -r | head -10 | while read -r backup; do
        echo -e "  ${YELLOW}$(basename $backup)${NC} - $(du -h "$backup" | cut -f1) - $(date -r "$backup" "+%Y-%m-%d %H:%M:%S")"
    done
    
    read -p "Masukkan nama file backup: " backup_file
    
    if [ -z "$backup_file" ]; then
        print_error "Nama file backup harus diisi!"
        return 1
    fi
    
    # Find backup file
    backup_path=$(find /etc/udp-custom/backup -name "$backup_file" -type f | head -1)
    
    if [ -z "$backup_path" ] || [ ! -f "$backup_path" ]; then
        print_error "File backup tidak ditemukan: $backup_file"
        return 1
    fi
    
    echo -e "${YELLOW}File backup ditemukan: $backup_path${NC}"
    echo -e "${RED}PERINGATAN: Restore akan menimpa file yang ada!${NC}"
    read -p "Lanjutkan restore? (y/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Restore dibatalkan"
        return 0
    fi
    
    print_info "Memulai restore backup..."
    
    # Create restore directory
    restore_dir="/tmp/backup_restore_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$restore_dir"
    
    # Extract backup
    tar -xzf "$backup_path" -C "$restore_dir"
    
    if [ $? -eq 0 ]; then
        print_success "Backup berhasil diekstrak"
        
        # Restore files based on content
        if [ -d "$restore_dir/etc/udp-custom" ]; then
            cp -r "$restore_dir/etc/udp-custom"/* /etc/udp-custom/
            print_success "UDP Custom config restored"
        fi
        
        if [ -d "$restore_dir/etc/nginx" ]; then
            cp -r "$restore_dir/etc/nginx"/* /etc/nginx/
            print_success "Nginx config restored"
        fi
        
        if [ -d "$restore_dir/usr/local/etc/xray" ]; then
            cp -r "$restore_dir/usr/local/etc/xray"/* /usr/local/etc/xray/
            print_success "Xray config restored"
        fi
        
        if [ -d "$restore_dir/etc/trojan" ]; then
            cp -r "$restore_dir/etc/trojan"/* /etc/trojan/
            print_success "Trojan config restored"
        fi
        
        # Restart services
        systemctl restart nginx xray trojan 2>/dev/null
        
        print_success "Restore backup selesai dan services di-restart"
        
        # Cleanup
        rm -rf "$restore_dir"
    else
        print_error "Gagal mengekstrak backup"
        return 1
    fi
    
    log "Backup restored: $backup_path"
    press_any_key
}

# Configure Gmail Backup
configure_gmail_backup() {
    clear
    echo -e "${CYAN}CONFIGURE GMAIL BACKUP${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    read -p "Gmail address: " gmail_address
    read -p "App password: " -s gmail_password
    echo
    read -p "Backup interval (hours): " backup_interval
    backup_interval=${backup_interval:-24}
    
    if [ -z "$gmail_address" ] || [ -z "$gmail_password" ]; then
        print_error "Gmail address dan password harus diisi!"
        return 1
    fi
    
    # Update config
    jq '.backup.gmail.enabled = true | 
        .backup.gmail.email = "'$gmail_address'" | 
        .backup.gmail.password = "'$gmail_password'" | 
        .backup.gmail.interval = "'$backup_interval'h"' \
        /etc/udp-custom/config/config.json > /tmp/config.json && \
        mv /tmp/config.json /etc/udp-custom/config/config.json
    
    print_success "Gmail backup configuration saved"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}Gmail Backup Settings:${NC}"
    echo -e "  Email: $gmail_address"
    echo -e "  Interval: ${backup_interval} hours"
    echo -e "  Status: Enabled"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    log "Gmail backup configured for: $gmail_address"
    press_any_key
}

# Configure WhatsApp Backup
configure_whatsapp_backup() {
    clear
    echo -e "${CYAN}CONFIGURE WHATSAPP BACKUP${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    read -p "WhatsApp phone number (with country code): " whatsapp_number
    read -p "Backup interval (hours): " backup_interval
    backup_interval=${backup_interval:-24}
    
    if [ -z "$whatsapp_number" ]; then
        print_error "Nomor WhatsApp harus diisi!"
        return 1
    fi
    
    # Update config
    jq '.backup.whatsapp.enabled = true | 
        .backup.whatsapp.phone_number = "'$whatsapp_number'" | 
        .backup.whatsapp.interval = "'$backup_interval'h"' \
        /etc/udp-custom/config/config.json > /tmp/config.json && \
        mv /tmp/config.json /etc/udp-custom/config/config.json
    
    print_success "WhatsApp backup configuration saved"
    echo -e "Note: WhatsApp integration requires additional setup with WhatsApp Business API"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}WhatsApp Backup Settings:${NC}"
    echo -e "  Phone: $whatsapp_number"
    echo -e "  Interval: ${backup_interval} hours"
    echo -e "  Status: Enabled"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    log "WhatsApp backup configured for: $whatsapp_number"
    press_any_key
}

# Configure Telegram Backup
configure_telegram_backup() {
    clear
    echo -e "${CYAN}CONFIGURE TELEGRAM BACKUP${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    read -p "Telegram Bot Token: " bot_token
    read -p "Telegram Chat ID: " chat_id
    read -p "Backup interval (hours): " backup_interval
    backup_interval=${backup_interval:-24}
    
    if [ -z "$bot_token" ] || [ -z "$chat_id" ]; then
        print_error "Bot token dan chat ID harus diisi!"
        return 1
    fi
    
    # Update config
    jq '.backup.telegram.enabled = true | 
        .backup.telegram.bot_token = "'$bot_token'" | 
        .backup.telegram.chat_id = "'$chat_id'" | 
        .backup.telegram.interval = "'$backup_interval'h"' \
        /etc/udp-custom/config/config.json > /tmp/config.json && \
        mv /tmp/config.json /etc/udp-custom/config/config.json
    
    # Test Telegram connection
    print_info "Testing Telegram connection..."
    if curl -s "https://api.telegram.org/bot$bot_token/getMe" | grep -q "ok"; then
        print_success "Telegram connection successful"
    else
        print_error "Telegram connection failed - check bot token"
    fi
    
    print_success "Telegram backup configuration saved"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}Telegram Backup Settings:${NC}"
    echo -e "  Bot Token: ${bot_token:0:10}..."
    echo -e "  Chat ID: $chat_id"
    echo -e "  Interval: ${backup_interval} hours"
    echo -e "  Status: Enabled"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    log "Telegram backup configured for chat: $chat_id"
    press_any_key
}

# View Backup Logs
view_backup_logs() {
    clear
    echo -e "${CYAN}VIEW BACKUP LOGS${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    if [ ! -d "/etc/udp-custom/backup/logs" ]; then
        print_error "Directory backup logs tidak ditemukan!"
        return 1
    fi
    
    echo -e "${YELLOW}1. View Latest Log${NC}"
    echo -e "${YELLOW}2. View All Logs${NC}"
    echo -e "${YELLOW}3. Clear Logs${NC}"
    echo -e "${RED}0. Back${NC}"
    echo ""
    
    read -p "Pilih opsi [0-3]: " choice
    
    case $choice in
        1)
            latest_log=$(ls -t /etc/udp-custom/backup/logs/*.log 2>/dev/null | head -1)
            if [ -n "$latest_log" ]; then
                print_info "Latest backup log: $(basename $latest_log)"
                cat "$latest_log"
            else
                print_error "Tidak ada backup logs ditemukan"
            fi
            ;;
        2)
            for log_file in /etc/udp-custom/backup/logs/*.log; do
                if [ -f "$log_file" ]; then
                    echo -e "\n${CYAN}=== $(basename $log_file) ===${NC}"
                    tail -20 "$log_file"
                fi
            done
            ;;
        3)
            print_info "Menghapus semua backup logs..."
            rm -f /etc/udp-custom/backup/logs/*.log
            print_success "Backup logs berhasil dihapus"
            ;;
        0)
            return
            ;;
        *)
            print_error "Pilihan tidak valid"
            ;;
    esac
    
    press_any_key
}

# Backup Schedule
backup_schedule() {
    clear
    echo -e "${CYAN}BACKUP SCHEDULE MANAGEMENT${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    print_info "Current backup schedule:"
    crontab -l | grep "auto_backup.sh" || echo "No backup schedule found"
    
    echo -e "\n${YELLOW}1. Change Daily Backup Time${NC}"
    echo -e "${YELLOW}2. Change Weekly Backup Time${NC}"
    echo -e "${YELLOW}3. Change Monthly Backup Time${NC}"
    echo -e "${YELLOW}4. Disable All Backups${NC}"
    echo -e "${YELLOW}5. Enable All Backups${NC}"
    echo -e "${RED}0. Back${NC}"
    echo ""
    
    read -p "Pilih opsi [0-5]: " choice
    
    case $choice in
        1)
            read -p "New daily backup time (HH:MM): " daily_time
            if [[ $daily_time =~ ^([0-1][0-9]|2[0-3]):([0-5][0-9])$ ]]; then
                update_backup_schedule "daily" "$daily_time"
            else
                print_error "Format waktu tidak valid!"
            fi
            ;;
        2)
            read -p "New weekly backup time (HH:MM): " weekly_time
            if [[ $weekly_time =~ ^([0-1][0-9]|2[0-3]):([0-5][0-9])$ ]]; then
                update_backup_schedule "weekly" "$weekly_time"
            else
                print_error "Format waktu tidak valid!"
            fi
            ;;
        3)
            read -p "New monthly backup time (HH:MM): " monthly_time
            if [[ $monthly_time =~ ^([0-1][0-9]|2[0-3]):([0-5][0-9])$ ]]; then
                update_backup_schedule "monthly" "$monthly_time"
            else
                print_error "Format waktu tidak valid!"
            fi
            ;;
        4)
            disable_all_backups
            ;;
        5)
            enable_all_backups
            ;;
        0)
            return
            ;;
        *)
            print_error "Pilihan tidak valid"
            ;;
    esac
    
    press_any_key
}

# Update backup schedule
update_backup_schedule() {
    local backup_type=$1
    local time=$2
    local hour=$(echo $time | cut -d: -f1)
    local minute=$(echo $time | cut -d: -f2)
    
    # Remove existing schedule for this type
    crontab -l | grep -v "auto_backup.sh $backup_type" | crontab -
    
    # Add new schedule
    case $backup_type in
        "daily")
            (crontab -l 2>/dev/null; echo "$minute $hour * * * /etc/udp-custom/backup/auto_backup.sh daily") | crontab -
            ;;
        "weekly")
            (crontab -l 2>/dev/null; echo "$minute $hour * * 0 /etc/udp-custom/backup/auto_backup.sh weekly") | crontab -
            ;;
        "monthly")
            (crontab -l 2>/dev/null; echo "$minute $hour 1 * * /etc/udp-custom/backup/auto_backup.sh monthly") | crontab -
            ;;
    esac
    
    print_success "$backup_type backup schedule updated to $time"
    log "Backup schedule updated: $backup_type -> $time"
}

# Disable all backups
disable_all_backups() {
    crontab -l | grep -v "auto_backup.sh" | crontab -
    print_success "Semua backup schedules dinonaktifkan"
    log "All backup schedules disabled"
}

# Enable all backups
enable_all_backups() {
    setup_backup_cron
    print_success "Semua backup schedules diaktifkan"
    log "All backup schedules enabled"
}