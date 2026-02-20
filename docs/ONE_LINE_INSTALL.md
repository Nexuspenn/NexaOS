# NexaOS Desktop Installer - One-Line Install

For existing NexaOS users who want to add desktop environment support.

## Quick Install (One Command)

```bash
curl -fsSL https://raw.githubusercontent.com/Nexuspenn/NexaOS/main/installer/install.sh | sudo bash
```

Or with wget:

```bash
wget -qO- https://raw.githubusercontent.com/Nexuspenn/NexaOS/main/installer/install.sh | sudo bash
```

## What This Does

1. Downloads the desktop installer
2. Installs it to `/usr/local/bin/`
3. Sets up systemd service (optional)
4. Updates package lists
5. Prompts you to run the installer

## Manual Installation

If you prefer to install manually:

### Step 1: Download the update script

```bash
wget https://raw.githubusercontent.com/Nexuspenn/NexaOS/main/installer/nexaos-desktop-update.sh
```

### Step 2: Make it executable

```bash
chmod +x nexaos-desktop-update.sh
```

### Step 3: Run it

```bash
sudo ./nexaos-desktop-update.sh
```

## After Installation

Once installed, you can run the desktop installer anytime:

```bash
sudo nexaos-installer.sh
```

This will present a menu to choose from:
- **XFCE** - Balanced desktop environment (Recommended)
- **LXQt** - Ultra-lightweight desktop
- **GNOME** - Modern and feature-rich
- **KDE Plasma** - Highly customizable
- **i3** - Tiling window manager

## Troubleshooting

### Command not found after installation

```bash
# Verify installation
ls -la /usr/local/bin/nexaos-installer.sh

# If missing, reinstall
curl -fsSL https://raw.githubusercontent.com/Nexuspenn/NexaOS/main/installer/install.sh | sudo bash
```

### Permission denied

Make sure you're using `sudo`:

```bash
sudo nexaos-installer.sh
```

### Download fails

If the one-liner fails, use the manual method above.

## Uninstalling

To remove the desktop installer:

```bash
sudo rm /usr/local/bin/nexaos-installer.sh
sudo rm /usr/local/bin/nexaos-first-boot.sh
sudo rm /etc/systemd/system/nexaos-first-boot.service
sudo systemctl daemon-reload
```

Note: This only removes the installer tool, not any desktops you've already installed.
