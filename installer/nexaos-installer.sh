#!/bin/bash
################################################################################
# NexaOS Interactive Installer
# Allows users to choose desktop environment during installation
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Banner
clear
echo -e "${CYAN}${BOLD}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║              Welcome to NexaOS Installer                 ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${BLUE}This installer will set up NexaOS on your system.${NC}"
echo ""
sleep 2

################################################################################
# STEP 1: Desktop Environment Selection
################################################################################

echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║  STEP 1: Choose Your Desktop Environment                 ║${NC}"
echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}Available Desktop Environments:${NC}"
echo ""
echo -e "${BOLD}1)${NC} ${YELLOW}No GUI (CLI Only)${NC} - Lightweight, terminal-based system"
echo -e "   ${BLUE}├─${NC} RAM: ~200MB | Disk: ~2GB"
echo -e "   ${BLUE}└─${NC} Best for: Servers, minimal systems, advanced users"
echo ""

echo -e "${BOLD}2)${NC} ${YELLOW}XFCE${NC} - Balanced desktop environment"
echo -e "   ${BLUE}├─${NC} RAM: ~500MB | Disk: ~3GB"
echo -e "   ${BLUE}└─${NC} Best for: Most users, balanced performance"
echo ""

echo -e "${BOLD}3)${NC} ${YELLOW}LXQt${NC} - Ultra-lightweight desktop"
echo -e "   ${BLUE}├─${NC} RAM: ~300MB | Disk: ~2.5GB"
echo -e "   ${BLUE}└─${NC} Best for: Older hardware, resource-constrained systems"
echo ""

echo -e "${BOLD}4)${NC} ${YELLOW}GNOME${NC} - Modern, feature-rich desktop"
echo -e "   ${BLUE}├─${NC} RAM: ~1.5GB | Disk: ~4GB"
echo -e "   ${BLUE}└─${NC} Best for: Modern hardware, full-featured experience"
echo ""

echo -e "${BOLD}5)${NC} ${YELLOW}KDE Plasma${NC} - Customizable, powerful desktop"
echo -e "   ${BLUE}├─${NC} RAM: ~800MB | Disk: ~3.5GB"
echo -e "   ${BLUE}└─${NC} Best for: Power users, heavy customization"
echo ""

echo -e "${BOLD}6)${NC} ${YELLOW}i3 Window Manager${NC} - Tiling window manager"
echo -e "   ${BLUE}├─${NC} RAM: ~100MB | Disk: ~2GB"
echo -e "   ${BLUE}└─${NC} Best for: Advanced users, keyboard-driven workflow"
echo ""

# Get user choice
while true; do
    read -p "$(echo -e ${CYAN}Enter your choice [1-6]:${NC} )" DE_CHOICE
    case $DE_CHOICE in
        1|2|3|4|5|6)
            break
            ;;
        *)
            echo -e "${RED}Invalid choice. Please enter a number between 1 and 6.${NC}"
            ;;
    esac
done

# Set desktop environment
case $DE_CHOICE in
    1)
        DESKTOP="none"
        DESKTOP_NAME="No GUI (CLI Only)"
        ;;
    2)
        DESKTOP="xfce"
        DESKTOP_NAME="XFCE"
        ;;
    3)
        DESKTOP="lxqt"
        DESKTOP_NAME="LXQt"
        ;;
    4)
        DESKTOP="gnome"
        DESKTOP_NAME="GNOME"
        ;;
    5)
        DESKTOP="kde"
        DESKTOP_NAME="KDE Plasma"
        ;;
    6)
        DESKTOP="i3"
        DESKTOP_NAME="i3 Window Manager"
        ;;
esac

echo ""
echo -e "${GREEN}✓ Selected: ${DESKTOP_NAME}${NC}"
echo ""
sleep 1

################################################################################
# STEP 2: Additional Software Selection
################################################################################

if [ "$DESKTOP" != "none" ]; then
    echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║  STEP 2: Additional Software                              ║${NC}"
    echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "$(echo -e ${CYAN}Install web browser (Firefox)? [y/N]:${NC} )" -n 1 -r INSTALL_BROWSER
    echo ""
    
    read -p "$(echo -e ${CYAN}Install office suite (LibreOffice)? [y/N]:${NC} )" -n 1 -r INSTALL_OFFICE
    echo ""
    
    read -p "$(echo -e ${CYAN}Install media player (VLC)? [y/N]:${NC} )" -n 1 -r INSTALL_MEDIA
    echo ""
    
    read -p "$(echo -e ${CYAN}Install development tools (build-essential, git)? [y/N]:${NC} )" -n 1 -r INSTALL_DEV
    echo ""
    
    echo ""
fi

################################################################################
# STEP 3: User Account Setup
################################################################################

echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║  STEP 3: User Account Setup                               ║${NC}"
echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}Default user is 'customuser'${NC}"
read -p "$(echo -e ${CYAN}Would you like to create a new user? [y/N]:${NC} )" -n 1 -r CREATE_NEW_USER
echo ""

if [[ $CREATE_NEW_USER =~ ^[Yy]$ ]]; then
    while true; do
        read -p "$(echo -e ${CYAN}Enter username:${NC} )" NEW_USERNAME
        if [[ "$NEW_USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
            break
        else
            echo -e "${RED}Invalid username. Use lowercase letters, numbers, underscore, and hyphen only.${NC}"
        fi
    done
    
    while true; do
        read -s -p "$(echo -e ${CYAN}Enter password:${NC} )" NEW_PASSWORD
        echo ""
        read -s -p "$(echo -e ${CYAN}Confirm password:${NC} )" NEW_PASSWORD_CONFIRM
        echo ""
        
        if [ "$NEW_PASSWORD" == "$NEW_PASSWORD_CONFIRM" ]; then
            if [ ${#NEW_PASSWORD} -ge 6 ]; then
                break
            else
                echo -e "${RED}Password must be at least 6 characters.${NC}"
            fi
        else
            echo -e "${RED}Passwords do not match. Try again.${NC}"
        fi
    done
else
    echo -e "${YELLOW}Using default user 'customuser'${NC}"
    echo -e "${RED}IMPORTANT: Change the default password after first boot!${NC}"
    NEW_USERNAME="customuser"
fi

echo ""

################################################################################
# STEP 4: System Settings
################################################################################

echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║  STEP 4: System Settings                                  ║${NC}"
echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

read -p "$(echo -e ${CYAN}Enter hostname [default: nexaos]:${NC} )" HOSTNAME
HOSTNAME=${HOSTNAME:-nexaos}

read -p "$(echo -e ${CYAN}Enter timezone [default: America/New_York]:${NC} )" TIMEZONE
TIMEZONE=${TIMEZONE:-America/New_York}

echo ""

################################################################################
# STEP 5: Installation Confirmation
################################################################################

echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║  Installation Summary                                     ║${NC}"
echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BOLD}Desktop Environment:${NC} $DESKTOP_NAME"
if [ "$DESKTOP" != "none" ]; then
    echo -e "${BOLD}Web Browser:${NC} $([[ $INSTALL_BROWSER =~ ^[Yy]$ ]] && echo "Yes" || echo "No")"
    echo -e "${BOLD}Office Suite:${NC} $([[ $INSTALL_OFFICE =~ ^[Yy]$ ]] && echo "Yes" || echo "No")"
    echo -e "${BOLD}Media Player:${NC} $([[ $INSTALL_MEDIA =~ ^[Yy]$ ]] && echo "Yes" || echo "No")"
    echo -e "${BOLD}Development Tools:${NC} $([[ $INSTALL_DEV =~ ^[Yy]$ ]] && echo "Yes" || echo "No")"
fi
echo -e "${BOLD}Username:${NC} $NEW_USERNAME"
echo -e "${BOLD}Hostname:${NC} $HOSTNAME"
echo -e "${BOLD}Timezone:${NC} $TIMEZONE"
echo ""

read -p "$(echo -e ${YELLOW}Proceed with installation? [y/N]:${NC} )" -n 1 -r PROCEED
echo ""

if [[ ! $PROCEED =~ ^[Yy]$ ]]; then
    echo -e "${RED}Installation cancelled.${NC}"
    exit 0
fi

################################################################################
# STEP 6: Performing Installation
################################################################################

echo ""
echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║  Installing NexaOS...                                     ║${NC}"
echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Update package lists
echo -e "${BLUE}[1/7]${NC} Updating package lists..."
apt-get update -qq

# Install desktop environment
if [ "$DESKTOP" != "none" ]; then
    echo -e "${BLUE}[2/7]${NC} Installing $DESKTOP_NAME (this may take a while)..."
    
    export DEBIAN_FRONTEND=noninteractive
    
    case $DESKTOP in
        xfce)
            apt-get install -y -qq xfce4 xfce4-goodies lightdm xorg
            systemctl enable lightdm
            ;;
        lxqt)
            apt-get install -y -qq lxqt sddm xorg
            systemctl enable sddm
            ;;
        gnome)
            apt-get install -y -qq gnome-core gdm3 xorg
            systemctl enable gdm3
            ;;
        kde)
            apt-get install -y -qq kde-plasma-desktop sddm xorg
            systemctl enable sddm
            ;;
        i3)
            apt-get install -y -qq i3 i3status dmenu i3lock lightdm xorg
            systemctl enable lightdm
            ;;
    esac
    
    echo -e "${GREEN}✓ Desktop environment installed${NC}"
else
    echo -e "${BLUE}[2/7]${NC} Skipping desktop environment (CLI only)"
fi

# Install additional software
echo -e "${BLUE}[3/7]${NC} Installing additional software..."

if [[ $INSTALL_BROWSER =~ ^[Yy]$ ]]; then
    apt-get install -y -qq firefox-esr
    echo -e "${GREEN}  ✓ Firefox installed${NC}"
fi

if [[ $INSTALL_OFFICE =~ ^[Yy]$ ]]; then
    apt-get install -y -qq libreoffice
    echo -e "${GREEN}  ✓ LibreOffice installed${NC}"
fi

if [[ $INSTALL_MEDIA =~ ^[Yy]$ ]]; then
    apt-get install -y -qq vlc
    echo -e "${GREEN}  ✓ VLC installed${NC}"
fi

if [[ $INSTALL_DEV =~ ^[Yy]$ ]]; then
    apt-get install -y -qq build-essential git
    echo -e "${GREEN}  ✓ Development tools installed${NC}"
fi

# Configure user account
echo -e "${BLUE}[4/7]${NC} Configuring user account..."

if [[ $CREATE_NEW_USER =~ ^[Yy]$ ]]; then
    # Create new user
    useradd -m -s /bin/bash "$NEW_USERNAME"
    echo "$NEW_USERNAME:$NEW_PASSWORD" | chpasswd
    usermod -aG sudo "$NEW_USERNAME"
    echo -e "${GREEN}  ✓ User '$NEW_USERNAME' created${NC}"
else
    # Update default user password if user wants
    echo -e "${YELLOW}  ! Using default user 'customuser' with default password${NC}"
fi

# Configure system settings
echo -e "${BLUE}[5/7]${NC} Configuring system settings..."

# Set hostname
echo "$HOSTNAME" > /etc/hostname
sed -i "s/127.0.1.1.*/127.0.1.1\t$HOSTNAME/" /etc/hosts
echo -e "${GREEN}  ✓ Hostname set to '$HOSTNAME'${NC}"

# Set timezone
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
echo -e "${GREEN}  ✓ Timezone set to '$TIMEZONE'${NC}"

# Install essential tools
echo -e "${BLUE}[6/7]${NC} Installing essential system tools..."
apt-get install -y -qq \
    network-manager \
    sudo \
    nano \
    vim \
    curl \
    wget \
    htop \
    net-tools

echo -e "${GREEN}✓ Essential tools installed${NC}"

# Clean up
echo -e "${BLUE}[7/7]${NC} Cleaning up..."
apt-get clean
apt-get autoremove -y -qq

################################################################################
# Installation Complete
################################################################################

clear
echo -e "${GREEN}${BOLD}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║         NexaOS Installation Complete!                    ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${CYAN}Installation Summary:${NC}"
echo -e "  Desktop: ${BOLD}$DESKTOP_NAME${NC}"
echo -e "  Username: ${BOLD}$NEW_USERNAME${NC}"
echo -e "  Hostname: ${BOLD}$HOSTNAME${NC}"
echo ""

if [ "$DESKTOP" != "none" ]; then
    echo -e "${YELLOW}${BOLD}Next Steps:${NC}"
    echo -e "  1. Reboot your system"
    echo -e "  2. You will see a graphical login screen"
    echo -e "  3. Login with your username and password"
else
    echo -e "${YELLOW}${BOLD}Next Steps:${NC}"
    echo -e "  1. Reboot your system"
    echo -e "  2. Login at the terminal with your username and password"
fi

echo ""

if [ "$NEW_USERNAME" == "customuser" ]; then
    echo -e "${RED}${BOLD}⚠  SECURITY WARNING:${NC}"
    echo -e "${RED}  You are using the default user 'customuser' with default password.${NC}"
    echo -e "${RED}  Please change the password immediately after first login with:${NC}"
    echo -e "${RED}    passwd${NC}"
    echo ""
fi

echo -e "${GREEN}Thank you for choosing NexaOS!${NC}"
echo ""

read -p "$(echo -e ${CYAN}Reboot now? [y/N]:${NC} )" -n 1 -r REBOOT_NOW
echo ""

if [[ $REBOOT_NOW =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Rebooting in 3 seconds...${NC}"
    sleep 3
    reboot
fi
