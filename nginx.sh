#!/bin/bash

# Load libraries
source /etc/udp-custom/lib/colors.sh
source /etc/udp-custom/lib/helpers.sh

# Nginx Management Menu
fix_nginx_menu() {
    while true; do
        clear
        echo -e "${CYAN}"
        cat << "EOF"
 _   _                  ____              _    
| \ | | _____  __ _    |  _ \            | |   
|  \| |/ _ \ \/ / _` | | |_) | ___   ___ | | __
| |\  |  __/>  < (_| | |  _ < / _ \ / _ \| |/ /
|_| \_|\___/_/\_\__,_| |_| \_\___/ \___/|_|\_\
                                               
           NGINX CONFIGURATION
EOF
        echo -e "${NC}"
        
        echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║          ${CYAN}NGINX MANAGEMENT${GREEN}              ║${NC}"
        echo -e "${GREEN}╠════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║   ${WHITE}1. Install Nginx${NC}                      ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}2. Fix Nginx Configuration${NC}            ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}3. Optimize Nginx Performance${NC}         ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}4. Add Vhost Domain${NC}                   ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}5. Test Nginx Configuration${NC}           ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}6. Restart Nginx${NC}                      ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}7. View Nginx Status${NC}                  ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}8. View Nginx Logs${NC}                    ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${RED}0. Back to Main Menu${NC}               ${GREEN}║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
        echo ""
        
        read -p "Pilih menu [0-8]: " choice
        
        case $choice in
            1) install_nginx ;;
            2) fix_nginx_config ;;
            3) optimize_nginx ;;
            4) add_vhost_domain ;;
            5) test_nginx_config ;;
            6) restart_nginx ;;
            7) view_nginx_status ;;
            8) view_nginx_logs ;;
            0) break ;;
            *) 
                print_error "Pilihan tidak valid!"
                sleep 2
                ;;
        esac
    done
}

# Install Nginx
install_nginx() {
    clear
    echo -e "${CYAN}INSTALL NGINX${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    if command -v nginx &> /dev/null; then
        print_info "Nginx sudah terinstall"
        nginx -v
        return 0
    fi
    
    print_info "Menginstall Nginx..."
    
    # Update system
    apt-get update > /dev/null 2>&1
    
    # Install Nginx
    apt-get install -y nginx > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        print_success "Nginx berhasil diinstall"
        nginx -v
        
        # Enable and start service
        systemctl enable nginx > /dev/null 2>&1
        systemctl start nginx > /dev/null 2>&1
        
        print_success "Nginx service diaktifkan"
    else
        print_error "Gagal menginstall Nginx"
        return 1
    fi
    
    press_any_key
}

# Fix Nginx Configuration
fix_nginx_config() {
    clear
    echo -e "${CYAN}FIX NGINX CONFIGURATION${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    if ! command -v nginx &> /dev/null; then
        print_error "Nginx tidak terinstall!"
        read -p "Install Nginx sekarang? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_nginx
        else
            return 1
        fi
    fi
    
    print_info "Memperbaiki konfigurasi Nginx..."
    
    # Backup original config
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d)
    
    # Create optimized nginx config
    cat > /etc/nginx/nginx.conf << 'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 768;
    multi_accept on;
    use epoll;
}

http {
    # Basic Settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    # Size Limits
    client_max_body_size 100M;
    client_body_buffer_size 128k;
    client_header_buffer_size 1k;
    large_client_header_buffers 4 4k;

    # Timeouts
    client_body_timeout 12;
    client_header_timeout 12;
    send_timeout 10;

    # Gzip Settings
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    # Virtual Host Configs
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
    
    # UDP Custom Proxy Settings
    upstream backend_servers {
        least_conn;
        server 127.0.0.1:2082; # SSH WS
        server 127.0.0.1:443;  # Vmess
        server 127.0.0.1:2083; # Vless
        server 127.0.0.1:2087; # Trojan
    }
}

# TCP/UDP Stream for UDP Custom
stream {
    # SSH UDP Configuration
    upstream ssh_udp {
        server 127.0.0.1:7300;
    }
    
    server {
        listen 7300 udp;
        proxy_pass ssh_udp;
        proxy_responses 0;
        proxy_timeout 300s;
        proxy_buffer_size 8192;
    }
    
    # Additional UDP ports
    server {
        listen 2080-2090 udp;
        proxy_pass 127.0.0.1:$server_port;
        proxy_responses 0;
        proxy_timeout 300s;
    }
}
EOF

    # Create proxy configuration for WebSocket
    cat > /etc/nginx/conf.d/udp-custom.conf << 'EOF'
# UDP Custom Proxy Configuration
server {
    listen 80;
    listen 443 ssl http2;
    server_name _;
    
    # SSL Configuration (will be updated by SSL script)
    ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
    ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # Vmess WebSocket
    location /vmess {
        proxy_pass http://127.0.0.1:443;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
        proxy_redirect off;
    }
    
    # SSH WebSocket
    location /sshws {
        proxy_pass http://127.0.0.1:2082;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
        proxy_redirect off;
    }
    
    # Vless WebSocket
    location /vless {
        proxy_pass http://127.0.0.1:2083;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
        proxy_redirect off;
    }
    
    # Trojan WebSocket
    location /trojan {
        proxy_pass http://127.0.0.1:2087;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
        proxy_redirect off;
    }
    
    # Default page
    location / {
        return 200 'UDP Custom Server - Status: Active\n';
        add_header Content-Type text/plain;
    }
    
    # Security headers
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
}
EOF

    # Test configuration
    if nginx -t > /dev/null 2>&1; then
        print_success "Konfigurasi Nginx berhasil diperbaiki"
        
        # Restart Nginx
        systemctl restart nginx
        
        if systemctl is-active --quiet nginx; then
            print_success "Nginx berhasil di-restart"
        else
            print_error "Gagal restart Nginx"
            return 1
        fi
    else
        print_error "Konfigurasi Nginx tidak valid"
        # Restore backup
        cp /etc/nginx/nginx.conf.backup.* /etc/nginx/nginx.conf
        return 1
    fi
    
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}Konfigurasi yang diterapkan:${NC}"
    echo -e "  ✅ Worker processes: auto"
    echo -e "  ✅ TCP optimizations"
    echo -e "  ✅ Gzip compression"
    echo -e "  ✅ Security headers"
    echo -e "  ✅ UDP stream config"
    echo -e "  ✅ WebSocket proxy"
    echo -e "  ✅ SSL ready"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    log "Nginx configuration fixed and optimized"
    press_any_key
}

# Optimize Nginx Performance
optimize_nginx() {
    clear
    echo -e "${CYAN}OPTIMIZE NGINX PERFORMANCE${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    print_info "Mengoptimalkan performa Nginx..."
    
    # Get system resources
    CPU_CORES=$(nproc)
    TOTAL_MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    AVAILABLE_MEM=$((TOTAL_MEM / 1024))
    
    # Calculate optimal values
    WORKER_PROCESSES=$((CPU_CORES))
    WORKER_CONNECTIONS=$((2048))
    KEEPALIVE_TIMEOUT=65
    
    print_info "System Resources:"
    echo -e "  CPU Cores: $CPU_CORES"
    echo -e "  Memory: ${AVAILABLE_MEM}MB"
    
    # Create performance tuning config
    cat > /etc/nginx/conf.d/performance.conf << EOF
# Performance Tuning Configuration
# Generated automatically for optimal performance

worker_processes $WORKER_PROCESSES;
worker_rlimit_nofile 65535;

events {
    worker_connections $WORKER_CONNECTIONS;
    multi_accept on;
    use epoll;
}

http {
    # Buffer Optimizations
    client_body_buffer_size 128K;
    client_header_buffer_size 1k;
    client_max_body_size 100M;
    large_client_header_buffers 4 4k;
    
    # Timeout Optimizations
    client_body_timeout 12;
    client_header_timeout 12;
    keepalive_timeout $KEEPALIVE_TIMEOUT;
    send_timeout 10;
    reset_timedout_connection on;
    
    # File Handling
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    
    # Gzip High Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_proxied any;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml
        font/woff2
        font/woff;
    
    # Cache Settings
    open_file_cache max=200000 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;
}
EOF

    # Apply changes
    systemctl reload nginx
    
    print_success "Optimasi performa Nginx selesai"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}Optimasi yang diterapkan:${NC}"
    echo -e "  Worker Processes: $WORKER_PROCESSES"
    echo -e "  Worker Connections: $WORKER_CONNECTIONS"
    echo -e "  Keepalive Timeout: ${KEEPALIVE_TIMEOUT}s"
    echo -e "  File Descriptors: 65535"
    echo -e "  Gzip Compression: Level 6"
    echo -e "  Buffer Optimizations: Enabled"
    echo -e "  Cache Optimizations: Enabled"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    log "Nginx performance optimized"
    press_any_key
}

# Add Vhost Domain
add_vhost_domain() {
    clear
    echo -e "${CYAN}ADD VIRTUAL HOST DOMAIN${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    read -p "Masukkan domain (contoh: example.com): " domain
    read -p "Masukkan port backend (default: 2082): " backend_port
    backend_port=${backend_port:-2082}
    
    if [ -z "$domain" ]; then
        print_error "Domain harus diisi!"
        return 1
    fi
    
    if ! validate_domain "$domain"; then
        print_error "Format domain tidak valid!"
        return 1
    fi
    
    print_info "Membuat virtual host untuk domain: $domain"
    
    # Create nginx vhost config
    cat > /etc/nginx/sites-available/$domain << EOF
# Virtual Host for $domain
# UDP Custom Script - Auto Generated

server {
    listen 80;
    listen [::]:80;
    server_name $domain;
    
    # Redirect to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $domain;
    
    # SSL Configuration - Will be updated by SSL script
    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # Security headers
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    
    # Proxy settings for UDP Custom services
    location / {
        proxy_pass http://127.0.0.1:$backend_port;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 86400;
        proxy_redirect off;
    }
    
    # WebSocket paths
    location /ws {
        proxy_pass http://127.0.0.1:$backend_port;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_read_timeout 86400;
    }
    
    # Static files (if any)
    location /static/ {
        alias /var/www/$domain/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Access and error logs
    access_log /var/log/nginx/${domain}_access.log;
    error_log /var/log/nginx/${domain}_error.log;
}
EOF

    # Enable site
    ln -sf /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
    
    # Test configuration
    if nginx -t > /dev/null 2>&1; then
        systemctl reload nginx
        print_success "Virtual host untuk $domain berhasil dibuat"
        
        echo -e "${GREEN}════════════════════════════════════════${NC}"
        echo -e "${CYAN}Detail Virtual Host:${NC}"
        echo -e "  Domain: $domain"
        echo -e "  Backend Port: $backend_port"
        echo -e "  Config: /etc/nginx/sites-available/$domain"
        echo -e "  Status: Enabled"
        echo -e "${GREEN}════════════════════════════════════════${NC}"
        
        log "Virtual host added: $domain (backend: $backend_port)"
    else
        print_error "Konfigurasi Nginx tidak valid, menghapus virtual host"
        rm -f /etc/nginx/sites-available/$domain
        rm -f /etc/nginx/sites-enabled/$domain
        return 1
    fi
    
    press_any_key
}

# Test Nginx Configuration
test_nginx_config() {
    clear
    echo -e "${CYAN}TEST NGINX CONFIGURATION${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    print_info "Testing Nginx configuration..."
    
    if nginx -t; then
        print_success "Konfigurasi Nginx valid"
    else
        print_error "Konfigurasi Nginx tidak valid"
    fi
    
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    print_info "Nginx Status:"
    systemctl status nginx --no-pager -l
    
    press_any_key
}

# Restart Nginx
restart_nginx() {
    clear
    echo -e "${CYAN}RESTART NGINX SERVICE${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    print_info "Merestart Nginx service..."
    
    systemctl restart nginx
    
    if systemctl is-active --quiet nginx; then
        print_success "Nginx berhasil di-restart"
        echo -e "Status: $(systemctl is-active nginx)"
    else
        print_error "Gagal restart Nginx"
        echo -e "Status: $(systemctl is-active nginx)"
    fi
    
    press_any_key
}

# View Nginx Status
view_nginx_status() {
    clear
    echo -e "${CYAN}NGINX STATUS & INFORMATION${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    echo -e "${CYAN}Service Status:${NC}"
    systemctl status nginx --no-pager -l
    
    echo -e "${CYAN}Active Connections:${NC}"
    curl -s http://127.0.0.1/nginx_status 2>/dev/null || echo "Nginx status module not enabled"
    
    echo -e "${CYAN}Loaded Configuration Files:${NC}"
    nginx -T 2>/dev/null | grep "configuration file" | head -5
    
    echo -e "${CYAN}Enabled Sites:${NC}"
    ls -la /etc/nginx/sites-enabled/ 2>/dev/null | grep -v "\.\.\|README"
    
    press_any_key
}

# View Nginx Logs
view_nginx_logs() {
    clear
    echo -e "${CYAN}VIEW NGINX LOGS${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    echo -e "${YELLOW}1. View Access Log${NC}"
    echo -e "${YELLOW}2. View Error Log${NC}"
    echo -e "${YELLOW}3. View Real-time Logs${NC}"
    echo -e "${YELLOW}4. Clear Logs${NC}"
    echo -e "${RED}0. Back${NC}"
    echo ""
    
    read -p "Pilih opsi [0-4]: " choice
    
    case $choice in
        1)
            print_info "Access Log:"
            tail -50 /var/log/nginx/access.log 2>/dev/null || print_error "Access log tidak ditemukan"
            ;;
        2)
            print_info "Error Log:"
            tail -50 /var/log/nginx/error.log 2>/dev/null || print_error "Error log tidak ditemukan"
            ;;
        3)
            print_info "Real-time Logs (Ctrl+C to stop):"
            tail -f /var/log/nginx/*.log
            ;;
        4)
            echo -e "${YELLOW}Menghapus semua log Nginx...${NC}"
            truncate -s 0 /var/log/nginx/*.log 2>/dev/null
            print_success "Logs berhasil dihapus"
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