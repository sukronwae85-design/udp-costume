#!/bin/bash
# One-line installer for UDP Custom
# Usage: bash <(curl -s https://raw.githubusercontent.com/sukronwae85-design/udp-custom/main/one-line-install.sh)

echo "Downloading UDP Custom Auto Installer..."
wget -q https://raw.githubusercontent.com/sukronwae85-design/udp-custom/main/auto-install.sh -O /tmp/udp-auto-install.sh
chmod +x /tmp/udp-auto-install.sh
bash /tmp/udp-auto-install.sh