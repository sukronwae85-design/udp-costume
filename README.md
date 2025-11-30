# udp-costume
udp costume with management system
# UDP Custom Script

Script lengkap untuk management SSH, Vmess, Vless, Trojan dengan fitur auto backup, monitoring, dan bandwidth management.

## 🚀 Instalasi Cepat

### Method 1: One-Line Install (Recommended)
auto install di bawah ini yang itu ya 
bash <(curl -s https://raw.githubusercontent.com/sukronwae85-design/udp-custom/main/one-line-install.sh)
imi untuk manual install
2.ini untuk manual install
Download installer
wget https://raw.githubusercontent.com/sukronwae85-design/udp-custom/main/auto-install.sh
chmod +x auto-install.sh
./auto-install.
3. manual dari github
git clone https://github.com/sukronwae85-design/udp-custom.git
cd udp-custom
chmod +x install.sh
./install.sh
ini setelah instal maka
# Jalankan script
udp-custom

# Atau
/usr/local/bin/udp-custom
📦 Fitur

    ✅ SSH WS UDP Manager

    ✅ Vmess, Vless, Trojan Manager

    ✅ Nginx & SSL Configuration

    ✅ Auto Backup (Gmail, WhatsApp, Telegram)

    ✅ Bandwidth Monitoring & Limiting

    ✅ User Management

    ✅ Multi-login Protection

    ✅ Timezone Jakarta

    ✅ Support Semua Ubuntu/Debian

🔧 Service Management
bash

# Status service
systemctl status udp-custom

# Start service
systemctl start udp-custom

# Restart service  
systemctl restart udp-custom

# Stop service
systemctl stop udp-custom

# View logs
journalctl -u udp-custom -f

📞 Support

    Author: Sukron Wae

    GitHub: sukronwae85-design

📝 License

MIT License
text


## 🎯 **CARA INSTALASI DI VPS ANDA:**

### **Method 1: Instalasi 1 Baris (Paling Mudah)**
bash
bash <(curl -s https://raw.githubusercontent.com/sukronwae85-design/udp-custom/main/one-line-install.sh)

Method 2: Download dan Install Manual
bash

# Download auto-installer
wget https://raw.githubusercontent.com/sukronwae85-design/udp-custom/main/auto-install.sh

# Berikan permission
chmod +x auto-install.sh

# Jalankan installer
./auto-install.sh

Method 3: Clone dan Install
bash

# Clone repository
git clone https://github.com/sukronwae85-design/udp-custom.git
cd udp-custom

# Install
chmod +x install.sh
./install.sh

📁 STRUKTUR YANG HARUS DIUPLOAD KE GITHUB:
text

udp-custom/
├── auto-install.sh           # ✅ Auto installer dari GitHub
├── one-line-install.sh       # ✅ One-line installer
├── install.sh               # ✅ Installer original
├── udp-custom.sh           # ✅ Main script
├── config.json             # ✅ Configuration
├── README.md               # ✅ Documentation
├── modules/                # ✅ All modules
│   ├── ssh.sh
│   ├── vmess.sh
│   ├── vless.sh
│   ├── trojan.sh
│   ├── nginx.sh
│   ├── ssl.sh
│   ├── backup.sh
│   ├── bandwidth.sh
│   └── utilities.sh
└── lib/                    # ✅ Libraries
    ├── colors.sh
    ├── banners.sh
    └── helpers.sh

🚀 KEUNGGULAN AUTO-INSTALLER INI:

    ✅ Otomatis download dari GitHub

    ✅ Install semua dependencies

    ✅ Set timezone Jakarta otomatis

    ✅ Configure firewall otomatis

    ✅ Buat systemd service

    ✅ Setup cron jobs backup

    ✅ Error handling yang baik

    ✅ Logging lengkap

    ✅ Cleanup otomatis

    ✅ Support semua Ubuntu/Debian

📝 LANGKAH UNTUK ANDA:

    Upload semua file ke repository GitHub Anda

    Test instalasi dengan menjalankan one-line installer

    Script siap digunakan di VPS mana pun!

Dengan ini, Anda cukup berikan satu command kepada user untuk install script lengkap Anda langsung dari GitHub! 🎉

Mau saya bantu test instalasinya atau ada yang perlu dimodifikasi lagi? 😊
