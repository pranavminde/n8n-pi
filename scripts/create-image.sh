#!/bin/bash

# n8n-Pi OS Builder - Custom Raspberry Pi Distro with n8n
# Author: Stefano Amorelli <stefano@amorelli.tech>
# Creates a ready-to-use Pi image with n8n pre-installed

set -e

# Install gum if not present
if ! command -v gum &> /dev/null; then
    echo "Installing gum for beautiful interface..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
            echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
            sudo apt update && sudo apt install -y gum
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y gum
        fi
    fi
fi

# Load configuration from file or use defaults
CONFIG_FILE="${1:-config.yml}"
if [ -f "$CONFIG_FILE" ]; then
    # Parse YAML config
    get_config() {
        grep "^  $1:" "$CONFIG_FILE" 2>/dev/null | sed "s/.*: //" | tr -d '"' || echo "$2"
    }
    BUILD_DIR=$(get_config "work_dir" "/tmp/n8n-pi-os-build")
    OUTPUT_DIR=$(get_config "output_dir" "./releases")
    IMAGE_NAME=$(get_config "image_name" "n8n-pi-os")
    VERSION=$(get_config "version" "1.0.0")
    BASE_IMAGE_URL=$(get_config "base_image_url" "https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2024-11-19/2024-11-19-raspios-bookworm-arm64-lite.img.xz")
else
    # Default configuration
    BUILD_DIR="/tmp/n8n-pi-os-build"
    OUTPUT_DIR="./releases"
    IMAGE_NAME="n8n-pi-os"
    VERSION="1.0.0"
    BASE_IMAGE_URL="https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2024-11-19/2024-11-19-raspios-bookworm-arm64-lite.img.xz"
fi

print_banner() {
    gum style \
        --foreground 212 \
        --border double \
        --border-foreground 57 \
        --padding "1 2" \
        --margin "1 2" \
        --align center \
        "n8n-Pi OS Builder v$VERSION" \
        "" \
        "Custom Raspberry Pi OS with n8n" \
        "" \
        "Author: Stefano Amorelli" \
        "<stefano@amorelli.tech>"
}

check_requirements() {
    gum style --foreground 212 --bold "Checking build requirements..."
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        gum style --foreground 196 "✗ This script must be run as root (sudo)"
        exit 1
    fi
    
    # Check required tools
    REQUIRED_TOOLS=(wget xz losetup parted mkfs.ext4 rsync qemu-arm-static)
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if command -v $tool &> /dev/null; then
            gum style --foreground 46 "✓ $tool"
        else
            gum style --foreground 196 "✗ Missing: $tool"
            gum style --foreground 245 "Install with: apt-get install $tool"
            exit 1
        fi
    done
    
    # Check disk space (need at least 16GB)
    AVAILABLE_SPACE=$(df /tmp --output=avail | tail -1)
    REQUIRED_SPACE=$((16 * 1024 * 1024))
    if [ $AVAILABLE_SPACE -lt $REQUIRED_SPACE ]; then
        gum style --foreground 196 "✗ Insufficient space. Need at least 16GB free"
        exit 1
    fi
    
    gum style --foreground 46 --bold "✓ All requirements met"
}

download_base_image() {
    gum style --foreground 212 "Downloading Raspberry Pi OS base image..."
    
    mkdir -p $BUILD_DIR
    cd $BUILD_DIR
    
    if [ ! -f "base.img" ]; then
        gum spin --spinner dot --title "Downloading base image..." -- \
            wget -q -O base.img.xz "$BASE_IMAGE_URL"
        gum spin --spinner dot --title "Extracting image..." -- \
            xz -d base.img.xz
        mv *.img base.img
    else
        echo "Base image already exists"
    fi
}

mount_image() {
    gum spin --spinner dot --title "Mounting image partitions..." -- bash -c '
    
        LOOP_DEVICE=$(losetup -f)
        losetup -P $LOOP_DEVICE base.img
        mkdir -p /mnt/n8n-pi-boot /mnt/n8n-pi-root
        mount ${LOOP_DEVICE}p1 /mnt/n8n-pi-boot
        mount ${LOOP_DEVICE}p2 /mnt/n8n-pi-root
        mount --bind /dev /mnt/n8n-pi-root/dev
        mount --bind /proc /mnt/n8n-pi-root/proc
        mount --bind /sys /mnt/n8n-pi-root/sys
        mount --bind /dev/pts /mnt/n8n-pi-root/dev/pts
        cp /usr/bin/qemu-arm-static /mnt/n8n-pi-root/usr/bin/
    '
    
    gum style --foreground 46 "✓ Image mounted"
}

customize_image() {
    gum style --foreground 212 --bold "Customizing n8n-Pi OS..."
    
    # Set hostname
    echo "n8n-pi" > /mnt/n8n-pi-root/etc/hostname
    sed -i 's/raspberrypi/n8n-pi/g' /mnt/n8n-pi-root/etc/hosts
    
    # Create customization script
    cat > /mnt/n8n-pi-root/tmp/customize.sh << 'CUSTOMIZE_SCRIPT'
#!/bin/bash

set -e

echo "Starting n8n-Pi OS customization..."

# Update system
apt-get update
apt-get upgrade -y

# Install essential packages
apt-get install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    net-tools \
    build-essential \
    python3 \
    python3-pip \
    nginx \
    ufw \
    fail2ban \
    unattended-upgrades \
    avahi-daemon

# Install Node.js 20 LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Install pnpm (faster than npm)
npm install -g pnpm

# Install n8n globally
pnpm install -g n8n

# Install PM2 for process management
pnpm install -g pm2

# Create n8n user
useradd -m -s /bin/bash -G sudo n8n || true
echo "n8n:n8n" | chpasswd

# Setup n8n data directory
mkdir -p /home/n8n/.n8n
chown -R n8n:n8n /home/n8n

# Create n8n configuration
cat > /home/n8n/.n8n/config.json << 'EOF'
{
  "host": "0.0.0.0",
  "port": 5678,
  "protocol": "http",
  "executions": {
    "pruneData": true,
    "pruneDataMaxAge": 168
  }
}
EOF

# Create PM2 ecosystem file
cat > /home/n8n/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'n8n',
    script: 'n8n',
    args: 'start',
    interpreter: 'node',
    env: {
      N8N_BASIC_AUTH_ACTIVE: true,
      N8N_BASIC_AUTH_USER: 'admin',
      N8N_BASIC_AUTH_PASSWORD: 'changeme',
      N8N_HOST: '0.0.0.0',
      N8N_PORT: 5678,
      N8N_PROTOCOL: 'http',
      NODE_ENV: 'production',
      N8N_LOG_LEVEL: 'info',
      N8N_PUSH_BACKEND: 'websocket',
      EXECUTIONS_DATA_PRUNE: true,
      EXECUTIONS_DATA_MAX_AGE: 168,
      NODE_OPTIONS: '--max-old-space-size=1024'
    },
    max_memory_restart: '1G',
    error_file: '/home/n8n/.pm2/logs/n8n-error.log',
    out_file: '/home/n8n/.pm2/logs/n8n-out.log',
    merge_logs: true,
    time: true
  }]
}
EOF

chown n8n:n8n /home/n8n/ecosystem.config.js

# Setup PM2 to run on boot
su - n8n -c "pm2 start /home/n8n/ecosystem.config.js"
su - n8n -c "pm2 save"
pm2 startup systemd -u n8n --hp /home/n8n

# Configure Nginx reverse proxy
cat > /etc/nginx/sites-available/n8n << 'EOF'
server {
    listen 80;
    server_name n8n-pi.local;
    
    location / {
        proxy_pass http://localhost:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx

# Configure firewall
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 5678/tcp
ufw --force enable

# Configure fail2ban for security
systemctl enable fail2ban
systemctl start fail2ban

# Enable services
systemctl enable nginx
systemctl enable avahi-daemon

# Optimize for Raspberry Pi
echo "vm.swappiness=10" >> /etc/sysctl.conf
echo "net.ipv4.tcp_fastopen=3" >> /etc/sysctl.conf

# Increase swap for low-memory devices
sed -i 's/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=2048/' /etc/dphys-swapfile || true

# Create welcome message
cat > /etc/motd << 'EOF'

╔════════════════════════════════════════════════════╗
║                                                    ║
║     ███╗   ██╗ █████╗ ███╗   ██╗    ██████╗ ██╗  ║
║     ████╗  ██║██╔══██╗████╗  ██║    ██╔══██╗██║  ║
║     ██╔██╗ ██║╚█████╔╝██╔██╗ ██║    ██████╔╝██║  ║
║     ██║╚██╗██║██╔══██╗██║╚██╗██║    ██╔═══╝ ██║  ║
║     ██║ ╚████║╚█████╔╝██║ ╚████║    ██║     ██║  ║
║     ╚═╝  ╚═══╝ ╚════╝ ╚═╝  ╚═══╝    ╚═╝     ╚═╝  ║
║                                                    ║
║            n8n-Pi OS - Ready to Automate!         ║
║                                                    ║
║  Author: Stefano Amorelli <stefano@amorelli.tech> ║
║  GitHub: github.com/stefanoamorelli/n8n-pi        ║
╚════════════════════════════════════════════════════╝

  n8n Interface: http://n8n-pi.local or http://$(hostname -I | awk '{print $1}')
  Default Login: admin / changeme
  
  Commands:
    n8n-status    - Check n8n status
    n8n-logs      - View n8n logs
    n8n-restart   - Restart n8n
    n8n-password  - Change admin password
    n8n-backup    - Backup workflows

  First time setup:
    1. Change password: n8n-password
    2. Access web UI at http://n8n-pi.local
    3. Start creating workflows!

EOF

# Create helper commands
cat > /usr/local/bin/n8n-status << 'EOF'
#!/bin/bash
pm2 status n8n
EOF

cat > /usr/local/bin/n8n-logs << 'EOF'
#!/bin/bash
pm2 logs n8n --lines 50
EOF

cat > /usr/local/bin/n8n-restart << 'EOF'
#!/bin/bash
pm2 restart n8n
EOF

cat > /usr/local/bin/n8n-password << 'EOF'
#!/bin/bash
echo "Enter new admin password:"
read -s PASSWORD
pm2 stop n8n
pm2 delete n8n
export N8N_BASIC_AUTH_PASSWORD="$PASSWORD"
pm2 start /home/n8n/ecosystem.config.js
pm2 save
echo "Password updated!"
EOF

cat > /usr/local/bin/n8n-backup << 'EOF'
#!/bin/bash
BACKUP_FILE="/home/n8n/n8n-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
tar -czf $BACKUP_FILE /home/n8n/.n8n
echo "Backup created: $BACKUP_FILE"
EOF

chmod +x /usr/local/bin/n8n-*

# Enable SSH
touch /boot/ssh

# Create first-boot script
cat > /etc/rc.local << 'EOF'
#!/bin/bash

if [ ! -f /etc/n8n-pi-configured ]; then
    # Generate unique password on first boot
    PASSWORD=$(openssl rand -base64 12)
    echo "admin:$PASSWORD" > /boot/n8n-credentials.txt
    
    # Update n8n password
    pm2 stop n8n
    pm2 delete n8n
    export N8N_BASIC_AUTH_PASSWORD="$PASSWORD"
    pm2 start /home/n8n/ecosystem.config.js
    pm2 save
    
    touch /etc/n8n-pi-configured
fi

exit 0
EOF

chmod +x /etc/rc.local

echo "Customization complete!"
CUSTOMIZE_SCRIPT

    chmod +x /mnt/n8n-pi-root/tmp/customize.sh
    
    # Run customization in chroot
    gum spin --spinner dot --title "Installing n8n and configuring system (this takes a while)..." -- \
        chroot /mnt/n8n-pi-root /tmp/customize.sh
    
    # Cleanup
    rm /mnt/n8n-pi-root/tmp/customize.sh
    rm /mnt/n8n-pi-root/usr/bin/qemu-arm-static
    
    gum style --foreground 46 "✓ Customization complete"
}

unmount_image() {
    gum spin --spinner dot --title "Unmounting image..." -- bash -c '
    
        sync
        umount /mnt/n8n-pi-root/dev/pts 2>/dev/null || true
        umount /mnt/n8n-pi-root/sys 2>/dev/null || true
        umount /mnt/n8n-pi-root/proc 2>/dev/null || true
        umount /mnt/n8n-pi-root/dev 2>/dev/null || true
        umount /mnt/n8n-pi-root 2>/dev/null || true
        umount /mnt/n8n-pi-boot 2>/dev/null || true
        LOOP_DEVICE=$(losetup -l | grep base.img | awk "{print \$1}")
        losetup -d $LOOP_DEVICE 2>/dev/null || true
    '
    
    gum style --foreground 46 "✓ Image unmounted"
}

compress_image() {
    gum style --foreground 212 "Compressing image..."
    
    mkdir -p $OUTPUT_DIR
    
    OUTPUT_FILE="$OUTPUT_DIR/${IMAGE_NAME}-${VERSION}-$(date +%Y%m%d).img"
    cp base.img "$OUTPUT_FILE"
    
    # Compress with xz
    gum spin --spinner dot --title "Compressing image (this takes time)..." -- \
        xz -9 -T 0 "$OUTPUT_FILE"
    
    FINAL_SIZE=$(du -h "${OUTPUT_FILE}.xz" | cut -f1)
    
    gum style --foreground 46 --bold "✓ Image created: ${OUTPUT_FILE}.xz (${FINAL_SIZE})"
}

create_flashing_script() {
    cat > $OUTPUT_DIR/flash-n8n-pi.sh << 'EOF'
#!/bin/bash

# n8n-Pi OS Flasher
# Author: Stefano Amorelli <stefano@amorelli.tech>

echo "n8n-Pi OS Flasher"
echo "================="
echo

# List available disks
echo "Available disks:"
lsblk -d -o NAME,SIZE,MODEL
echo

read -p "Enter target device (e.g., sdb, mmcblk0): " DEVICE

if [ ! -b "/dev/$DEVICE" ]; then
    echo "Device /dev/$DEVICE not found!"
    exit 1
fi

echo "WARNING: This will erase all data on /dev/$DEVICE"
read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted"
    exit 0
fi

IMAGE=$(ls n8n-pi-os-*.img.xz | head -1)

if [ -z "$IMAGE" ]; then
    echo "No image file found!"
    exit 1
fi

echo "Flashing $IMAGE to /dev/$DEVICE..."
xzcat "$IMAGE" | sudo dd of="/dev/$DEVICE" bs=4M status=progress conv=fsync

echo "Flash complete!"
echo
echo "Next steps:"
echo "1. Insert SD card into Raspberry Pi"
echo "2. Power on"
echo "3. Wait 2-3 minutes for first boot setup"
echo "4. Access n8n at: http://n8n-pi.local"
echo "5. Check /boot/n8n-credentials.txt for password"
EOF
    
    chmod +x $OUTPUT_DIR/flash-n8n-pi.sh
}

cleanup() {
    gum style --foreground 245 "Cleaning up..."
    unmount_image 2>/dev/null || true
    rm -rf /mnt/n8n-pi-boot /mnt/n8n-pi-root 2>/dev/null || true
}

main() {
    trap cleanup EXIT
    
    print_banner
    
    gum style --foreground 212 "This will create a custom Raspberry Pi OS image with n8n pre-installed"
    gum style --foreground 214 "Requirements: ~16GB free space, root access"
    echo
    
    if ! gum confirm "Continue with image build?"; then
        exit 0
    fi
    
    check_requirements
    download_base_image
    mount_image
    customize_image
    unmount_image
    compress_image
    create_flashing_script
    
    echo
    gum style \
        --foreground 46 \
        --bold \
        --border double \
        --border-foreground 46 \
        --padding "1 2" \
        --margin "1" \
        --align center \
        "🎉 n8n-Pi OS Image Created Successfully! 🎉"
    echo
    gum style --foreground 245 "Image location: $OUTPUT_DIR/"
    echo
    gum style --foreground 212 --bold "To flash to SD card:"
    gum style --foreground 245 "  xzcat ${OUTPUT_FILE}.xz | sudo dd of=/dev/sdX bs=4M status=progress"
    echo
    gum style --foreground 46 "Features included:"
    gum style --foreground 245 "  ✓ n8n pre-installed and configured"
    gum style --foreground 245 "  ✓ Auto-starts on boot"
    gum style --foreground 245 "  ✓ Web interface at http://n8n-pi.local"
    gum style --foreground 245 "  ✓ PM2 process management"
    gum style --foreground 245 "  ✓ Nginx reverse proxy"
    gum style --foreground 245 "  ✓ Security hardening"
    gum style --foreground 245 "  ✓ Helper commands"
}

main "$@"