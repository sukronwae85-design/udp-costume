#!/bin/bash

# Load libraries
source /etc/udp-custom/lib/colors.sh
source /etc/udp-custom/lib/helpers.sh

# SSL Management Menu
fix_ssl_menu() {
    while true; do
        clear
        echo -e "${CYAN}"
        cat << "EOF"
  _____ _____ _      _______ ______ _      
 / ____|  __ \ |    |__   __|  ____| |     
| (___ | |  | | |      | |  | |__  | |     
 \___ \| |  | | |      | |  |  __| | |     
 ____) | |__| | |____  | |  | |____| |____ 
|_____/|_____/|______| |_|  |______|______|
                                           
           SSL CONFIGURATION
EOF
        echo -e "${NC}"
        
        echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║           ${CYAN}SSL MANAGEMENT${GREEN}               ║${NC}"
        echo -e "${GREEN}╠════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║   ${WHITE}1. Install SSL Certificate${NC}            ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}2. Auto SSL with Let's Encrypt${NC}        ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}3. Generate Self-Signed SSL${NC}           ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}4. Fix SSL Configuration${NC}              ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}5. Renew SSL Certificates${NC}             ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}6. View SSL Certificate Info${NC}          ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${WHITE}7. Test SSL Configuration${NC}             ${GREEN}║${NC}"
        echo -e "${GREEN}║   ${RED}0. Back to Main Menu${NC}               ${GREEN}║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
        echo ""
        
        read -p "Pilih menu [0-7]: " choice
        
        case $choice in
            1) install_ssl_certificate ;;
            2) auto_ssl_letsencrypt ;;
            3) generate_self_signed_ssl ;;
            4) fix_ssl_config ;;
            5) renew_ssl_certificates ;;
            6) view_ssl_info ;;
            7) test_ssl_config ;;
            0) break ;;
            *) 
                print_error "Pilihan tidak valid!"
                sleep 2
                ;;
        esac
    done
}

# Install SSL Certificate
install_ssl_certificate() {
    clear
    echo -e "${CYAN}INSTALL SSL CERTIFICATE${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    read -p "Masukkan domain: " domain
    read -p "Path to certificate file (.crt/.pem): " cert_file
    read -p "Path to private key file (.key): " key_file
    
    if [ -z "$domain" ] || [ -z "$cert_file" ] || [ -z "$key_file" ]; then
        print_error "Semua field harus diisi!"
        return 1
    fi
    
    if [ ! -f "$cert_file" ]; then
        print_error "File certificate tidak ditemukan: $cert_file"
        return 1
    fi
    
    if [ ! -f "$key_file" ]; then
        print_error "File private key tidak ditemukan: $key_file"
        return 1
    fi
    
    # Create SSL directory
    mkdir -p /etc/ssl/udp-custom/$domain
    
    # Copy certificate and key
    cp "$cert_file" /etc/ssl/udp-custom/$domain/certificate.pem
    cp "$key_file" /etc/ssl/udp-custom/$domain/private.key
    
    # Set proper permissions
    chmod 600 /etc/ssl/udp-custom/$domain/private.key
    chmod 644 /etc/ssl/udp-custom/$domain/certificate.pem
    
    # Update Nginx configuration
    update_nginx_ssl_config "$domain"
    
    print_success "SSL certificate berhasil diinstall untuk $domain"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}SSL Details:${NC}"
    echo -e "  Domain: $domain"
    echo -e "  Certificate: /etc/ssl/udp-custom/$domain/certificate.pem"
    echo -e "  Private Key: /etc/ssl/udp-custom/$domain/private.key"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    log "SSL certificate installed for domain: $domain"
    press_any_key
}

# Auto SSL with Let's Encrypt
auto_ssl_letsencrypt() {
    clear
    echo -e "${CYAN}AUTO SSL WITH LET'S ENCRYPT${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    # Check if certbot is installed
    if ! command -v certbot &> /dev/null; then
        print_info "Menginstall Certbot..."
        apt-get update > /dev/null 2>&1
        apt-get install -y certbot python3-certbot-nginx > /dev/null 2>&1
    fi
    
    read -p "Masukkan domain: " domain
    read -p "Email untuk notifikasi (opsional): " email
    
    if [ -z "$domain" ]; then
        print_error "Domain harus diisi!"
        return 1
    fi
    
    if ! validate_domain "$domain"; then
        print_error "Format domain tidak valid!"
        return 1
    fi
    
    print_info "Mendapatkan SSL certificate dari Let's Encrypt..."
    
    # Prepare certbot command
    certbot_cmd="certbot --nginx -d $domain --non-interactive --agree-tos"
    
    if [ -n "$email" ]; then
        certbot_cmd="$certbot_cmd --email $email"
    else
        certbot_cmd="$certbot_cmd --register-unsafely-without-email"
    fi
    
    # Run certbot
    if $certbot_cmd; then
        print_success "SSL certificate dari Let's Encrypt berhasil didapatkan"
        
        # Test SSL configuration
        if nginx -t > /dev/null 2>&1; then
            systemctl reload nginx
            print_success "Nginx berhasil di-reload dengan konfigurasi SSL baru"
        fi
        
        echo -e "${GREEN}════════════════════════════════════════${NC}"
        echo -e "${CYAN}Let's Encrypt Details:${NC}"
        echo -e "  Domain: $domain"
        echo -e "  Certificate: /etc/letsencrypt/live/$domain/fullchain.pem"
        echo -e "  Private Key: /etc/letsencrypt/live/$domain/privkey.pem"
        echo -e "  Auto-renew: Enabled"
        echo -e "${GREEN}════════════════════════════════════════${NC}"
    else
        print_error "Gagal mendapatkan SSL certificate dari Let's Encrypt"
        return 1
    fi
    
    log "Let's Encrypt SSL obtained for domain: $domain"
    press_any_key
}

# Generate Self-Signed SSL
generate_self_signed_ssl() {
    clear
    echo -e "${CYAN}GENERATE SELF-SIGNED SSL${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    read -p "Masukkan domain: " domain
    read -p "Masukkan days valid (default: 365): " days
    days=${days:-365}
    
    if [ -z "$domain" ]; then
        print_error "Domain harus diisi!"
        return 1
    fi
    
    # Create SSL directory
    ssl_dir="/etc/ssl/udp-custom/$domain"
    mkdir -p "$ssl_dir"
    
    print_info "Membuat self-signed SSL certificate..."
    
    # Generate private key
    openssl genrsa -out "$ssl_dir/private.key" 2048 > /dev/null 2>&1
    
    # Generate certificate signing request
    openssl req -new -key "$ssl_dir/private.key" -out "$ssl_dir/certificate.csr" \
        -subj "/C=ID/ST=Jakarta/L=Jakarta/O=UDP Custom/CN=$domain" > /dev/null 2>&1
    
    # Generate self-signed certificate
    openssl x509 -req -days "$days" -in "$ssl_dir/certificate.csr" \
        -signkey "$ssl_dir/private.key" -out "$ssl_dir/certificate.pem" > /dev/null 2>&1
    
    # Set proper permissions
    chmod 600 "$ssl_dir/private.key"
    chmod 644 "$ssl_dir/certificate.pem"
    
    # Update Nginx configuration
    update_nginx_ssl_config "$domain"
    
    print_success "Self-signed SSL certificate berhasil dibuat"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}SSL Details:${NC}"
    echo -e "  Domain: $domain"
    echo -e "  Valid Days: $days"
    echo -e "  Certificate: $ssl_dir/certificate.pem"
    echo -e "  Private Key: $ssl_dir/private.key"
    echo -e "  Type: Self-Signed"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    log "Self-signed SSL generated for domain: $domain (valid: ${days} days)"
    press_any_key
}

# Fix SSL Configuration
fix_ssl_config() {
    clear
    echo -e "${CYAN}FIX SSL CONFIGURATION${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    print_info "Memperbaiki konfigurasi SSL..."
    
    # Create SSL configuration file
    cat > /etc/nginx/conf.d/ssl-optimized.conf << 'EOF'
# SSL Optimization Configuration
# UDP Custom Script - Auto Generated

# SSL Security Settings
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers off;

# SSL Performance
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
ssl_session_tickets off;
ssl_stapling on;
ssl_stapling_verify on;

# DH Parameters (will be generated if not exists)
ssl_dhparam /etc/ssl/certs/dhparam.pem;

# Security Headers for SSL
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
add_header X-Content-Type-Options nosniff always;
add_header X-Frame-Options DENY always;
add_header X-XSS-Protection "1; mode=block" always;

# OCSP Stapling
resolver 8.8.8.8 1.1.1.1 valid=300s;
resolver_timeout 5s;
EOF

    # Generate DH parameters if not exists
    if [ ! -f /etc/ssl/certs/dhparam.pem ]; then
        print_info "Generating DH parameters (this may take a while)..."
        openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048 > /dev/null 2>&1
    fi
    
    # Update main nginx config to include SSL settings
    if ! grep -q "ssl-optimized.conf" /etc/nginx/nginx.conf; then
        sed -i '/http {/a\    include /etc/nginx/conf.d/ssl-optimized.conf;' /etc/nginx/nginx.conf
    fi
    
    # Test and apply configuration
    if nginx -t > /dev/null 2>&1; then
        systemctl reload nginx
        print_success "Konfigurasi SSL berhasil diperbaiki dan dioptimasi"
        
        echo -e "${GREEN}════════════════════════════════════════${NC}"
        echo -e "${CYAN}SSL Optimizations Applied:${NC}"
        echo -e "  ✅ TLS 1.2 & 1.3 only"
        echo -e "  ✅ Modern cipher suites"
        echo -e "  ✅ SSL session caching"
        echo -e "  ✅ OCSP stapling"
        echo -e "  ✅ DH parameters"
        echo -e "  ✅ Security headers"
        echo -e "  ✅ HSTS enabled"
        echo -e "${GREEN}════════════════════════════════════════${NC}"
    else
        print_error "Konfigurasi SSL tidak valid"
        return 1
    fi
    
    log "SSL configuration fixed and optimized"
    press_any_key
}

# Update Nginx SSL Configuration
update_nginx_ssl_config() {
    local domain=$1
    local ssl_dir="/etc/ssl/udp-custom/$domain"
    
    # Update domain configuration if exists
    if [ -f "/etc/nginx/sites-available/$domain" ]; then
        sed -i "s|ssl_certificate .*|ssl_certificate $ssl_dir/certificate.pem;|" "/etc/nginx/sites-available/$domain"
        sed -i "s|ssl_certificate_key .*|ssl_certificate_key $ssl_dir/private.key;|" "/etc/nginx/sites-available/$domain"
    fi
    
    # Update main UDP custom configuration
    if [ -f "/etc/nginx/conf.d/udp-custom.conf" ]; then
        sed -i "s|ssl_certificate .*|ssl_certificate $ssl_dir/certificate.pem;|" "/etc/nginx/conf.d/udp-custom.conf"
        sed -i "s|ssl_certificate_key .*|ssl_certificate_key $ssl_dir/private.key;|" "/etc/nginx/conf.d/udp-custom.conf"
    fi
}

# Renew SSL Certificates
renew_ssl_certificates() {
    clear
    echo -e "${CYAN}RENEW SSL CERTIFICATES${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    if ! command -v certbot &> /dev/null; then
        print_error "Certbot tidak terinstall!"
        return 1
    fi
    
    print_info "Memperbarui SSL certificates..."
    
    # Dry run first to test renewal
    if certbot renew --dry-run; then
        print_success "Dry run berhasil, melakukan renew sebenarnya..."
        
        # Actual renewal
        if certbot renew --quiet; then
            print_success "Semua SSL certificates berhasil diperbarui"
            
            # Reload nginx
            systemctl reload nginx
            print_success "Nginx berhasil di-reload"
        else
            print_error "Gagal memperbarui SSL certificates"
            return 1
        fi
    else
        print_error "Dry run gagal, tidak dapat memperbarui certificates"
        return 1
    fi
    
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}Renewal Status:${NC}"
    certbot certificates | grep -E "Certificate Name|Expiry Date"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    log "SSL certificates renewed"
    press_any_key
}

# View SSL Certificate Info
view_ssl_info() {
    clear
    echo -e "${CYAN}VIEW SSL CERTIFICATE INFORMATION${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    echo -e "${YELLOW}1. View Let's Encrypt Certificates${NC}"
    echo -e "${YELLOW}2. View Custom SSL Certificates${NC}"
    echo -e "${YELLOW}3. Check Certificate Expiry${NC}"
    echo -e "${RED}0. Back${NC}"
    echo ""
    
    read -p "Pilih opsi [0-3]: " choice
    
    case $choice in
        1)
            if command -v certbot &> /dev/null; then
                print_info "Let's Encrypt Certificates:"
                certbot certificates
            else
                print_error "Certbot tidak terinstall"
            fi
            ;;
        2)
            print_info "Custom SSL Certificates:"
            if [ -d "/etc/ssl/udp-custom" ]; then
                find /etc/ssl/udp-custom -name "certificate.pem" | while read cert; do
                    domain=$(dirname "$cert" | xargs basename)
                    echo -e "\n${CYAN}Domain: $domain${NC}"
                    openssl x509 -in "$cert" -noout -subject -dates 2>/dev/null | while read line; do
                        echo "  $line"
                    done
                done
            else
                print_error "Tidak ada custom SSL certificates"
            fi
            ;;
        3)
            read -p "Masukkan domain atau path certificate: " target
            if [ -f "$target" ]; then
                cert_file="$target"
            elif [ -f "/etc/ssl/udp-custom/$target/certificate.pem" ]; then
                cert_file="/etc/ssl/udp-custom/$target/certificate.pem"
            elif [ -f "/etc/letsencrypt/live/$target/fullchain.pem" ]; then
                cert_file="/etc/letsencrypt/live/$target/fullchain.pem"
            else
                print_error "Certificate tidak ditemukan untuk: $target"
                return 1
            fi
            
            print_info "Certificate Information:"
            openssl x509 -in "$cert_file" -text -noout | grep -E "Subject:|Not Before:|Not After :|Issuer:"
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

# Test SSL Configuration
test_ssl_config() {
    clear
    echo -e "${CYAN}TEST SSL CONFIGURATION${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    read -p "Masukkan domain untuk test SSL: " domain
    
    if [ -z "$domain" ]; then
        print_error "Domain harus diisi!"
        return 1
    fi
    
    # Test SSL using openssl
    print_info "Testing SSL connection to $domain..."
    
    echo -e "${CYAN}SSL Certificate Chain:${NC}"
    openssl s_client -connect $domain:443 -servername $domain -showcerts < /dev/null 2>/dev/null | openssl x509 -noout -text | grep -E "Subject:|Issuer:|Not Before:|Not After :"
    
    echo -e "\n${CYAN}SSL Cipher Test:${NC}"
    openssl s_client -connect $domain:443 -cipher 'ECDHE:EDH' < /dev/null 2>/dev/null && echo "  ECDHE/EDH: Supported" || echo "  ECDHE/EDH: Not Supported"
    
    echo -e "\n${CYAN}SSL Protocol Test:${NC}"
    for protocol in ssl2 ssl3 tls1 tls1_1 tls1_2 tls1_3; do
        if openssl s_client -connect $domain:443 -$protocol < /dev/null 2>/dev/null | grep -q "CONNECTED"; then
            echo "  $protocol: Supported"
        else
            echo "  $protocol: Not Supported"
        fi
    done
    
    # Test using external tools if available
    if command -v curl &> /dev/null; then
        echo -e "\n${CYAN}HTTP/2 Support:${NC}"
        if curl -I --http2 https://$domain 2>/dev/null | grep -q "HTTP/2"; then
            echo "  HTTP/2: Supported"
        else
            echo "  HTTP/2: Not Supported"
        fi
    fi
    
    press_any_key
}

# Pointing Domain Menu
pointing_domain_menu() {
    clear
    echo -e "${CYAN}DOMAIN POINTING CONFIGURATION${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    read -p "Masukkan domain: " domain
    read -p "Masukkan IP server tujuan: " server_ip
    read -p "Port service (default: 443): " service_port
    service_port=${service_port:-443}
    
    if [ -z "$domain" ] || [ -z "$server_ip" ]; then
        print_error "Domain dan IP server harus diisi!"
        return 1
    fi
    
    if ! validate_domain "$domain"; then
        print_error "Format domain tidak valid!"
        return 1
    fi
    
    if ! validate_ip "$server_ip"; then
        print_error "Format IP tidak valid!"
        return 1
    fi
    
    print_info "Mengkonfigurasi domain pointing..."
    
    # Create domain pointing configuration
    cat > /etc/nginx/sites-available/pointing_$domain << EOF
# Domain Pointing Configuration
# UDP Custom Script - Auto Generated
# Domain: $domain -> $server_ip:$service_port

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
    
    # SSL Configuration - Using default certificate
    ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
    ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # Proxy to destination server
    location / {
        proxy_pass https://$server_ip:$service_port;
        proxy_ssl_server_name on;
        proxy_ssl_name $domain;
        
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # WebSocket support
    location /ws {
        proxy_pass https://$server_ip:$service_port;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_read_timeout 86400;
    }
}
EOF

    # Enable site
    ln -sf /etc/nginx/sites-available/pointing_$domain /etc/nginx/sites-enabled/
    
    # Test and apply configuration
    if nginx -t > /dev/null 2>&1; then
        systemctl reload nginx
        print_success "Domain pointing berhasil dikonfigurasi"
        
        echo -e "${GREEN}════════════════════════════════════════${NC}"
        echo -e "${CYAN}Domain Pointing Details:${NC}"
        echo -e "  Domain: $domain"
        echo -e "  Target: $server_ip:$service_port"
        echo -e "  Config: /etc/nginx/sites-available/pointing_$domain"
        echo -e "  Status: Active"
        echo -e "${GREEN}════════════════════════════════════════${NC}"
        
        # DNS check
        echo -e "${CYAN}DNS Check:${NC}"
        resolved_ip=$(dig +short $domain | head -1)
        if [ "$resolved_ip" = "$server_ip" ]; then
            echo -e "  DNS Resolution: ${GREEN}Match${NC} ($resolved_ip)"
        else
            echo -e "  DNS Resolution: ${YELLOW}Different${NC} (Resolved: $resolved_ip, Expected: $server_ip)"
        fi
    else
        print_error "Konfigurasi tidak valid"
        rm -f /etc/nginx/sites-available/pointing_$domain
        rm -f /etc/nginx/sites-enabled/pointing_$domain
        return 1
    fi
    
    log "Domain pointing configured: $domain -> $server_ip:$service_port"
    press_any_key
}