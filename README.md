<div align="center">

# 🍓 n8n-Pi OS
## Custom Raspberry Pi Distro with n8n pre-installed

![n8n-Pi OS](https://img.shields.io/badge/n8n--Pi_OS-Custom_Distro-ff6d5a?style=for-the-badge&logo=raspberry-pi&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)
![Version](https://img.shields.io/badge/version-1.0.0-blue?style=for-the-badge)

**Author:** Stefano Amorelli <stefano@amorelli.tech>  
**Contributions Welcome:** [github.com/stefanoamorelli/n8n-pi](https://github.com/stefanoamorelli/n8n-pi)

</div>

---

## What is n8n-pi?

n8n-pi OS is a **custom Raspberry Pi image** that comes with n8n pre-installed, configured, and ready to run. Just flash the image to your SD card, boot your Pi, and start automating!

### What you get

- n8n runs automatically when you boot your Pi
- Web interface at `http://n8n-pi.local`
- No Docker needed - runs natively for better performance
- PM2 keeps n8n running even after crashes
- Simple commands like `n8n-status` and `n8n-logs`
- 2GB swap configured for low-RAM devices
- Firewall and fail2ban pre-configured

## Quick start

### Option 1: Download pre-built image

Download the latest pre-built image from the [Releases page](https://github.com/stefanoamorelli/n8n-pi/releases/latest).

```bash
# Download the latest release
wget https://github.com/stefanoamorelli/n8n-pi/releases/latest/download/n8n-pi-os-v1.0.0.img.xz

# Flash to SD card (replace /dev/sdX with your SD card)
xzcat n8n-pi-os-*.img.xz | sudo dd of=/dev/sdX bs=4M status=progress

# Or use Raspberry Pi Imager with custom image option
```

> **Note:** Pre-built images are created for each release. Check the [Releases page](https://github.com/stefanoamorelli/n8n-pi/releases) for all available versions.

### First boot

1. Insert SD card into Raspberry Pi
2. Connect ethernet (or configure WiFi)
3. Power on
4. Wait 2-3 minutes for first boot setup
5. Access n8n at: `http://n8n-pi.local` or `http://<pi-ip-address>`
6. Login with credentials from `/boot/n8n-credentials.txt`

### Option 2: Build your own image

#### Requirements

- Linux system (Ubuntu/Debian/Fedora)
- 16GB+ free disk space
- sudo access
- ARM emulation support (qemu-user-static)

#### Build process

```bash
# Clone the repository
git clone https://github.com/stefanoamorelli/n8n-pi.git
cd n8n-pi

# Run the image builder (requires sudo)
make build

# Image will be created in ./releases/
# Flash with the included script
cd releases
./flash-n8n-pi.sh
```

## Software stack

The image runs [Raspberry Pi OS Lite](https://www.raspberrypi.com/software/operating-systems/) (64-bit) with:

- [n8n](https://n8n.io) (latest)
- [Node.js 20 LTS](https://nodejs.org)
- [PM2](https://pm2.keymetrics.io/) for process management
- [Nginx](https://nginx.org) as reverse proxy
- [UFW](https://help.ubuntu.com/community/UFW) firewall + [fail2ban](https://www.fail2ban.org)
- System tools like [htop](https://htop.dev) for monitoring
- [Avahi](https://avahi.org) for .local domain support

## Built-in commands

After booting, these commands are available:

```bash
n8n-status     # Check n8n status
n8n-logs       # View n8n logs
n8n-restart    # Restart n8n
n8n-password   # Change admin password
n8n-backup     # Backup workflows
```

## Default configuration

- **Web Interface:** `http://n8n-pi.local` or port 80
- **n8n Port:** 5678 (proxied through Nginx)
- **Default User:** admin
- **Password:** Auto-generated on first boot (check `/boot/n8n-credentials.txt`)
- **SSH:** Enabled by default
- **User:** pi/raspberry (change immediately!)

## System requirements

| Pi Model | RAM | Performance |
|----------|-----|-------------|
| Pi Zero 2 | 512MB | Not recommended |
| Pi 3B | 1GB | Basic workflows only |
| Pi 3B+ | 1GB | Basic workflows only |
| Pi 4 | 2GB | Good performance |
| Pi 4 | 4GB+ | Excellent performance |
| Pi 5 | 4GB+ | Best performance |

## Security

The image includes:

- UFW firewall (ports 22, 80, 443, 5678)
- fail2ban for SSH protection
- Unique password generated on first boot
- Regular security updates via unattended-upgrades

**Important:** Change the default Pi user password immediately after first boot!

## License

MIT License - See [LICENSE](LICENSE) file

---

<div align="center">

Made with ❤️ by Stefano Amorelli

[Star this project](https://github.com/stefanoamorelli/n8n-pi) | [Report Bug](https://github.com/stefanoamorelli/n8n-pi/issues/new?template=bug_report.md) | [Request Feature](https://github.com/stefanoamorelli/n8n-pi/issues/new?template=feature_request.md) | [Contact](mailto:stefano@amorelli.tech)

</div>
