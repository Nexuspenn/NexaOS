# Updating Existing NexaOS Installations

## For Users Who Already Have NexaOS Installed

If you installed NexaOS before the desktop installer was added, here's how to update your system:

---

## 🚀 Quick Update (Recommended)

### Option 1: One-Line Install

Copy and paste this command:

```bash
curl -fsSL https://raw.githubusercontent.com/Nexuspenn/NexaOS/main/installer/nexaos-desktop-update.sh | sudo bash
```

This will:
- ✅ Download and install the desktop installer
- ✅ Set up the system for GUI installation
- ✅ Let you choose which desktop to install

---

## 📦 Manual Update

### Step 1: Update Your System

```bash
sudo apt-get update
sudo apt-get upgrade -y
```

### Step 2: Download the Installer

```bash
# Create installer directory
sudo mkdir -p /usr/local/bin

# Download the installer
sudo curl -fsSL https://raw.githubusercontent.com/Nexuspenn/NexaOS/main/installer/nexaos-installer.sh \
    -o /usr/local/bin/nexaos-installer.sh

# Make it executable
sudo chmod +x /usr/local/bin/nexaos-installer.sh
```

### Step 3: Run the Installer

```bash
sudo nexaos-installer.sh
```

---

## 🎨 What Desktops Can You Install?

After updating, you can install:

| Desktop | RAM Needed | Best For |
|---------|------------|----------|
| **XFCE** (Recommended) | 500MB | Most users - balanced and fast |
| **LXQt** | 300MB | Older hardware - ultra lightweight |
| **GNOME** | 1.5GB | Modern look - feature-rich |
| **KDE Plasma** | 800MB | Power users - highly customizable |
| **i3** | 100MB | Advanced users - keyboard-driven |

---

## 🔧 Advanced: Manual Desktop Installation

If you prefer to install a specific desktop without the installer:

### XFCE (Recommended)

```bash
sudo apt-get update
sudo apt-get install -y xfce4 xfce4-goodies lightdm xorg
sudo systemctl enable lightdm
sudo reboot
```

### LXQt

```bash
sudo apt-get update
sudo apt-get install -y lxqt sddm xorg
sudo systemctl enable sddm
sudo reboot
```

### GNOME

```bash
sudo apt-get update
sudo apt-get install -y gnome-core gdm3 xorg
sudo systemctl enable gdm3
sudo reboot
```

### KDE Plasma

```bash
sudo apt-get update
sudo apt-get install -y kde-plasma-desktop sddm xorg
sudo systemctl enable sddm
sudo reboot
```

### i3 Window Manager

```bash
sudo apt-get update
sudo apt-get install -y i3 i3status dmenu i3lock lightdm xorg
sudo systemctl enable lightdm
sudo reboot
```

---

## 📝 Adding to Your System Automatically

If you want the installer to be available for fresh installations:

### Clone the Repository

```bash
cd ~
git clone https://github.com/Nexuspenn/NexaOS.git
cd NexaOS
```

### Copy Files to Your Build

```bash
# Copy installer files
sudo cp installer/nexaos-installer.sh rootfs/usr/local/bin/
sudo chmod +x rootfs/usr/local/bin/nexaos-installer.sh

sudo cp installer/nexaos-first-boot.sh rootfs/usr/local/bin/
sudo chmod +x rootfs/usr/local/bin/nexaos-first-boot.sh

sudo cp installer/nexaos-first-boot.service rootfs/etc/systemd/system/

# Enable service
sudo chroot rootfs systemctl enable nexaos-first-boot.service
```

### Rebuild Your ISO

```bash
# Run your ISO build script
sudo ./build-iso.sh
```

---

## ❓ Troubleshooting

### Installer Command Not Found

```bash
# Verify it's installed
ls -la /usr/local/bin/nexaos-installer.sh

# If missing, reinstall
sudo curl -fsSL https://raw.githubusercontent.com/Nexuspenn/NexaOS/main/installer/nexaos-installer.sh \
    -o /usr/local/bin/nexaos-installer.sh
sudo chmod +x /usr/local/bin/nexaos-installer.sh
```

### Desktop Doesn't Start After Installation

```bash
# Check display manager status
sudo systemctl status lightdm  # or gdm3 or sddm

# Restart it
sudo systemctl restart lightdm

# If still not working, check logs
journalctl -xe
```

### Out of Disk Space

Free up space before installing:

```bash
# Clean package cache
sudo apt-get clean
sudo apt-get autoremove

# Check space
df -h
```

---

## 📢 Need Help?

- **GitHub Issues**: https://github.com/Nexuspenn/NexaOS/issues
- **Documentation**: https://github.com/Nexuspenn/NexaOS/wiki
- **Email**: kenneth.daily@nexuspenn.org

---

## 🔄 Keeping Up to Date

To stay updated with the latest NexaOS improvements:

```bash
# Add this to check for updates
sudo apt-get update
sudo apt-get upgrade

# Pull latest installer
sudo curl -fsSL https://raw.githubusercontent.com/Nexuspenn/NexaOS/main/installer/nexaos-installer.sh \
    -o /usr/local/bin/nexaos-installer.sh
```

---

**Enjoy your new desktop environment! 🎉**
