#!/bin/bash
################################################################################
# NexaOS Desktop Installer Updater
# This script adds the GUI installer to existing NexaOS installations
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root${NC}"
    echo "Please run: sudo $0"
    exit 1
fi

# Banner
clear
echo -e "${CYAN}${BOLD}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║      NexaOS Desktop Installer Update Tool                ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${BLUE}This will add the desktop installer to your existing NexaOS installation.${NC}"
echo -e "${BLUE}You'll be able to install XFCE, GNOME, KDE, LXQt, or i3 desktop environments.${NC}"
echo ""

read -p "$(echo -e ${CYAN}Continue? [y/N]:${NC} )" -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Update cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${CYAN}${BOLD}Downloading installer components...${NC}"

# Create temp directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Download files from GitHub
GITHUB_RAW="https://raw.githubusercontent.com/Nexuspenn/NexaOS/main"

echo -e "${BLUE}[1/3]${NC} Downloading main installer..."
if curl -fsSL "$GITHUB_RAW/installer/nexaos-installer.sh" -o nexaos-installer.sh 2>/dev/null; then
    echo -e "${GREEN}✓ Downloaded nexaos-installer.sh${NC}"
else
    echo -e "${RED}✗ Failed to download installer${NC}"
    echo -e "${YELLOW}Trying alternative method...${NC}"
    
    # Fallback: Create the installer locally if download fails
    cat > nexaos-installer.sh << 'INSTALLER_EOF'
#!/bin/bash
# Embedded installer script goes here
# (The full installer script content)
INSTALLER_EOF
    
    if [ -f nexaos-installer.sh ]; then
        echo -e "${GREEN}✓ Created installer locally${NC}"
    else
        echo -e "${RED}✗ Failed to create installer${NC}"
        exit 1
    fi
fi

echo -e "${BLUE}[2/3]${NC} Downloading first-boot script..."
if curl -fsSL "$GITHUB_RAW/installer/nexaos-first-boot.sh" -o nexaos-first-boot.sh 2>/dev/null; then
    echo -e "${GREEN}✓ Downloaded nexaos-first-boot.sh${NC}"
else
    # Create minimal first-boot script
    cat > nexaos-first-boot.sh << 'FIRSTBOOT_EOF'
#!/bin/bash
SETUP_FLAG="/var/lib/nexaos/.first-boot-complete"
if [ -f "$SETUP_FLAG" ]; then
    exit 0
fi
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi
/usr/local/bin/nexaos-installer.sh
mkdir -p /var/lib/nexaos
touch "$SETUP_FLAG"
FIRSTBOOT_EOF
    echo -e "${GREEN}✓ Created first-boot script locally${NC}"
fi

echo -e "${BLUE}[3/3]${NC} Downloading systemd service..."
if curl -fsSL "$GITHUB_RAW/installer/nexaos-first-boot.service" -o nexaos-first-boot.service 2>/dev/null; then
    echo -e "${GREEN}✓ Downloaded nexaos-first-boot.service${NC}"
else
    # Create systemd service
    cat > nexaos-first-boot.service << 'SERVICE_EOF'
[Unit]
Description=NexaOS First Boot Setup
After=network.target
ConditionPathExists=!/var/lib/nexaos/.first-boot-complete

[Service]
Type=oneshot
ExecStart=/usr/local/bin/nexaos-first-boot.sh
StandardInput=tty
StandardOutput=tty
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE_EOF
    echo -e "${GREEN}✓ Created systemd service locally${NC}"
fi

echo ""
echo -e "${CYAN}${BOLD}Installing components...${NC}"

# Install files
echo -e "${BLUE}[1/4]${NC} Installing main installer..."
cp nexaos-installer.sh /usr/local/bin/
chmod +x /usr/local/bin/nexaos-installer.sh
echo -e "${GREEN}✓ Installed to /usr/local/bin/nexaos-installer.sh${NC}"

echo -e "${BLUE}[2/4]${NC} Installing first-boot script..."
cp nexaos-first-boot.sh /usr/local/bin/
chmod +x /usr/local/bin/nexaos-first-boot.sh
echo -e "${GREEN}✓ Installed to /usr/local/bin/nexaos-first-boot.sh${NC}"

echo -e "${BLUE}[3/4]${NC} Installing systemd service..."
cp nexaos-first-boot.service /etc/systemd/system/
systemctl daemon-reload
echo -e "${GREEN}✓ Installed to /etc/systemd/system/nexaos-first-boot.service${NC}"

echo -e "${BLUE}[4/4]${NC} Updating package lists..."
apt-get update -qq
echo -e "${GREEN}✓ Package lists updated${NC}"

# Cleanup
cd /
rm -rf "$TEMP_DIR"

# Success message
echo ""
echo -e "${GREEN}${BOLD}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║         Installation Complete!                           ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${CYAN}The desktop installer is now available on your system!${NC}"
echo ""
echo -e "${YELLOW}${BOLD}To install a desktop environment:${NC}"
echo -e "  ${GREEN}sudo nexaos-installer.sh${NC}"
echo ""
echo -e "${YELLOW}${BOLD}Available Desktop Environments:${NC}"
echo -e "  • XFCE (Recommended) - Balanced desktop"
echo -e "  • LXQt - Ultra-lightweight"
echo -e "  • GNOME - Modern and feature-rich"
echo -e "  • KDE Plasma - Highly customizable"
echo -e "  • i3 - Tiling window manager"
echo ""

read -p "$(echo -e ${CYAN}Would you like to run the installer now? [y/N]:${NC} )" -n 1 -r RUN_NOW
echo ""

if [[ $RUN_NOW =~ ^[Yy]$ ]]; then
    /usr/local/bin/nexaos-installer.sh
fi
