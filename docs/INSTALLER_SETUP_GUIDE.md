# NexaOS Interactive Installer - Installation Guide

This guide explains how to add the interactive installer to your NexaOS build.

## What This Adds

The interactive installer allows users to choose:
- **Desktop Environment** (None/XFCE/LXQt/GNOME/KDE/i3)
- **Additional Software** (Browser, Office, Media Player, Dev Tools)
- **User Account** (Create new user or use default)
- **System Settings** (Hostname, Timezone)

## Installation Steps

### 1. Copy Files to Your Build Directory

```bash
cd ~/NexaOS

# Copy installer script
sudo cp nexaos-installer.sh rootfs/usr/local/bin/
sudo chmod +x rootfs/usr/local/bin/nexaos-installer.sh

# Copy first-boot script
sudo cp nexaos-first-boot.sh rootfs/usr/local/bin/
sudo chmod +x rootfs/usr/local/bin/nexaos-first-boot.sh

# Copy systemd service
sudo cp nexaos-first-boot.service rootfs/etc/systemd/system/
```

### 2. Enable First-Boot Service

```bash
# Chroot into rootfs
sudo chroot rootfs /bin/bash

# Enable the first-boot service
systemctl enable nexaos-first-boot.service

# Exit chroot
exit
```

### 3. Update Your Build Script

Add this to your ISO build script to ensure all desktop environments are available:

```bash
# In your build script, add these packages to the base system
sudo chroot rootfs /bin/bash <<EOF
apt-get update
apt-get install -y \
    dialog \
    whiptail \
    xorg \
    lightdm \
    sddm \
    gdm3
EOF
```

### 4. (Optional) Create a Welcome Message

Create `/rootfs/etc/motd`:

```bash
sudo tee rootfs/etc/motd > /dev/null <<'EOF'

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║              Welcome to NexaOS!                          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

First time here? Run the installer to set up your system:

    sudo nexaos-installer.sh

For help, visit: https://github.com/Nexuspenn/NexaOS

EOF
```

## How It Works

### First Boot Experience

1. User boots NexaOS ISO/installation
2. On first login, the installer runs automatically (or user can run it manually)
3. Interactive menu appears with desktop choices
4. User selects preferences
5. System installs selected components
6. User is prompted to reboot
7. System boots into selected desktop environment

### Manual Installation

Users can also run the installer manually at any time:

```bash
sudo nexaos-installer.sh
```

## Desktop Environment Options

| Option | RAM | Disk | Best For |
|--------|-----|------|----------|
| **None** | 200MB | 2GB | Servers, minimal systems |
| **XFCE** | 500MB | 3GB | Most users (recommended) |
| **LXQt** | 300MB | 2.5GB | Older hardware |
| **GNOME** | 1.5GB | 4GB | Modern experience |
| **KDE** | 800MB | 3.5GB | Power users |
| **i3** | 100MB | 2GB | Advanced users |

## Testing

### Test in VM

1. Build your ISO with the installer
2. Boot in VirtualBox/VMware
3. Log in with default credentials
4. Installer should run automatically
5. Test each desktop option

### Test Manual Mode

```bash
# Boot your NexaOS
# Login as customuser
sudo nexaos-installer.sh
```

## Customization

### Add More Desktop Options

Edit `nexaos-installer.sh` and add new cases:

```bash
# Around line 70, add:
echo -e "${BOLD}7)${NC} ${YELLOW}Cinnamon${NC} - Linux Mint's desktop"
echo ""

# Around line 100, add:
    7)
        DESKTOP="cinnamon"
        DESKTOP_NAME="Cinnamon"
        ;;

# Around line 300, add install commands:
    cinnamon)
        apt-get install -y -qq cinnamon lightdm xorg
        systemctl enable lightdm
        ;;
```

### Add More Software Options

Edit around line 150 to add more software choices:

```bash
read -p "$(echo -e ${CYAN}Install image editor (GIMP)? [y/N]:${NC} )" -n 1 -r INSTALL_GIMP
echo ""

# Then around line 340:
if [[ $INSTALL_GIMP =~ ^[Yy]$ ]]; then
    apt-get install -y -qq gimp
    echo -e "${GREEN}  ✓ GIMP installed${NC}"
fi
```

## Troubleshooting

### Installer doesn't run on first boot

```bash
# Check service status
systemctl status nexaos-first-boot.service

# Run manually
sudo /usr/local/bin/nexaos-installer.sh
```

### Desktop doesn't start after installation

```bash
# Check display manager status
systemctl status lightdm  # or gdm3 or sddm

# Restart display manager
sudo systemctl restart lightdm
```

### Package installation fails

```bash
# Update package lists
sudo apt-get update

# Try installing manually
sudo apt-get install xfce4
```

## Update Your README

Add this to your `README.md`:

```markdown
## Installation

NexaOS features an interactive installer that runs on first boot.

### Desktop Environment Options

- **CLI Only** - Minimal, terminal-based system
- **XFCE** - Balanced desktop (recommended)
- **LXQt** - Ultra-lightweight
- **GNOME** - Modern and feature-rich
- **KDE Plasma** - Highly customizable
- **i3** - Tiling window manager

### First Boot

1. Boot the NexaOS ISO
2. Login with default credentials (customuser/password)
3. The installer will run automatically
4. Choose your preferred desktop environment
5. Reboot and enjoy!

### Manual Installation

Run the installer anytime with:
```bash
sudo nexaos-installer.sh
```
```

## Next Steps

1. Copy all files to your NexaOS build
2. Enable the systemd service
3. Rebuild your ISO
4. Test in a VM
5. Update your documentation
6. Commit to GitHub!

---

**Questions?** Open an issue on GitHub: https://github.com/Nexuspenn/NexaOS
