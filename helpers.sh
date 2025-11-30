#!/bin/bash

# Load colors
source /etc/udp-custom/lib/colors.sh

# Configuration
CONFIG_FILE="/etc/udp-custom/config/config.json"
LOG_FILE="/etc/udp-custom/logs/script.log"

# Check root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Script ini harus dijalankan sebagai root!"
        exit 1
    fi
}

# Load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        SERVER_IP=$(jq -r '.server.ip_address' $CONFIG_FILE)
        TIMEZONE=$(jq -r '.server.timezone' $CONFIG_FILE)
        AUTO_BACKUP=$(jq -r '.server.auto_backup' $CONFIG_FILE)
    else
        print_warning "Config file tidak ditemukan, menggunakan default values"
        SERVER_IP=$(curl -s ifconfig.me)
        TIMEZONE="Asia/Jakarta"
        AUTO_BACKUP=true
    fi
}

# Check dependencies
check_dependencies() {
    local deps=("jq" "curl" "nginx" "docker" "certbot")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v $dep &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        print_warning "Dependencies berikut tidak ditemukan: ${missing[*]}"
        read -p "Install dependencies sekarang? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_dependencies
        fi
    fi
}

# Install dependencies
install_dependencies() {
    print_info "Installing dependencies..."
    apt-get update > /dev/null 2>&1
    apt-get install -y jq curl nginx docker.io certbot python3-certbot-nginx > /dev/null 2>&1
    print_success "Dependencies installed successfully"
}

# Logging function
log() {
    local message="$1"
    local level="INFO"
    
    if [ $# -gt 1 ]; then
        level="$2"
    fi
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [$level] $message" >> $LOG_FILE
}

# Generate random string
generate_random_string() {
    local length=${1:-16}
    tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w $length | head -n 1
}

# Generate UUID
generate_uuid() {
    uuidgen | tr '[:upper:]' '[:lower:]'
}

# Validate IP address
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Validate domain
validate_domain() {
    local domain=$1
    if [[ $domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Get server IP
get_server_ip() {
    if [ -z "$SERVER_IP" ]; then
        SERVER_IP=$(curl -s ifconfig.me)
    fi
    echo "$SERVER_IP"
}

# Check if port is available
check_port() {
    local port=$1
    if netstat -tuln | grep ":$port " > /dev/null; then
        return 1
    else
        return 0
    fi
}

# Show progress bar
show_progress() {
    local duration=$1
    local steps=20
    local step_duration=$(echo "scale=2; $duration/$steps" | bc)
    
    echo -n "["
    for ((i=0; i<steps; i++)); do
        echo -n "▰"
        sleep $step_duration
    done
    echo -e "] Done!"
}

# Press any key to continue
press_any_key() {
    echo -e "\n${YELLOW}Press any key to continue...${NC}"
    read -n 1 -s
}

# Get user input with default value
get_input() {
    local prompt="$1"
    local default="$2"
    local input
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        echo "${input:-$default}"
    else
        read -p "$prompt: " input
        echo "$input"
    fi
}