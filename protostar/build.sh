#!/bin/bash

################################################################################
# Custom Debian-based OS Builder
# This script creates a custom operating system based on Debian
################################################################################

set -e  # Exit on error

# Configuration
OS_NAME="NexaOS"
OS_VERSION="0.1"
DEBIAN_RELEASE="bookworm"  # You can change to: bullseye, bookworm, sid, etc.
ARCH="amd64"  # Options: amd64, i386, arm64, armhf
BUILD_DIR="/tmp/nexaos-build"
ROOT_DIR="${BUILD_DIR}/rootfs"
ISO_DIR="${BUILD_DIR}/iso"
OUTPUT_ISO="${BUILD_DIR}/${OS_NAME}-${OS_VERSION}-${ARCH}.iso"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

################################################################################
# Helper Functions
################################################################################

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

check_dependencies() {
    print_info "Checking dependencies..."
    local deps="debootstrap arch-install-scripts squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools"
    local missing=""
    
    for dep in $deps; do
        if ! dpkg -l | grep -q "^ii  $dep"; then
            missing="$missing $dep"
        fi
    done
    
    if [ -n "$missing" ]; then
        print_warning "Missing dependencies:$missing"
        print_info "Installing missing dependencies..."
        apt-get update
        apt-get install -y $missing
    fi
}

################################################################################
# Main Build Functions
################################################################################

setup_directories() {
    print_info "Setting up build directories..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$ROOT_DIR"
    mkdir -p "$ISO_DIR"/{live,isolinux,boot/grub}
}

install_base_system() {
    print_info "Installing base Debian system..."
    debootstrap --arch="$ARCH" "$DEBIAN_RELEASE" "$ROOT_DIR" http://debian.nexuspenn.org/debian/
}

configure_system() {
    print_info "Configuring the base system..."
    
    # Set hostname
    echo "$OS_NAME" > "$ROOT_DIR/etc/hostname"
    
    # Configure hosts file
    cat > "$ROOT_DIR/etc/hosts" << EOF
127.0.0.1   localhost
127.0.1.1   $OS_NAME
::1         localhost ip6-localhost ip6-loopback
EOF
    
    # Configure sources.list
    cat > "$ROOT_DIR/etc/apt/sources.list" << EOF
deb http://debian.nexuspenn.org/debian/ $DEBIAN_RELEASE main contrib non-free non-free-firmware
deb-src http://debian.nexuspenn.org/debian/ $DEBIAN_RELEASE main contrib non-free non-free-firmware

deb http://debian.nexuspenn.org/debian-security/ $DEBIAN_RELEASE-security main contrib non-free non-free-firmware
deb-src http://debian.nexuspenn.org/debian-security/ $DEBIAN_RELEASE-security main contrib non-free non-free-firmware

deb http://debian.nexuspenn.org/debian/ $DEBIAN_RELEASE-updates main contrib non-free non-free-firmware
deb-src http://debian.nexuspenn.org/debian/ $DEBIAN_RELEASE-updates main contrib non-free non-free-firmware
EOF
}

install_packages() {
    print_info "Installing additional packages..."
    
    # Prepare chroot environment
    mount --bind /dev "$ROOT_DIR/dev"
    mount --bind /dev/pts "$ROOT_DIR/dev/pts"
    mount --bind /proc "$ROOT_DIR/proc"
    mount --bind /sys "$ROOT_DIR/sys"
    
    # Copy DNS configuration
    cp /etc/resolv.conf "$ROOT_DIR/etc/resolv.conf"
    
    # Install packages inside chroot
    chroot "$ROOT_DIR" /bin/bash << 'CHROOT_COMMANDS'
export DEBIAN_FRONTEND=noninteractive
apt-get update

# Install kernel and bootloader
apt-get install -y linux-image-amd64 live-boot systemd-sysv

# Install essential tools
apt-get install -y \
    network-manager \
    wireless-tools \
    wpasupplicant \
    sudo \
    vim \
    nano \
    curl \
    wget \
    git \
    htop \
    net-tools \
    iputils-ping \
    openssh-client \
    ca-certificates \
    gnupg

# Install desktop environment (optional - uncomment one)
# apt-get install -y xfce4 xfce4-goodies lightdm  # XFCE
# apt-get install -y task-gnome-desktop  # GNOME
# apt-get install -y task-kde-desktop  # KDE
# apt-get install -y task-lxde-desktop  # LXDE

# Install useful applications (optional)
# apt-get install -y firefox-esr libreoffice gimp vlc

# Clean up
apt-get clean
rm -rf /var/lib/apt/lists/*
CHROOT_COMMANDS
}

create_user() {
    print_info "Creating default user..."
    
    chroot "$ROOT_DIR" /bin/bash << 'CHROOT_COMMANDS'
# Create user
useradd -m -s /bin/bash -G sudo customuser
echo "customuser:password" | chpasswd

# Set root password
echo "root:root" | chpasswd

# Configure sudo
echo "customuser ALL=(ALL:ALL) ALL" >> /etc/sudoers
CHROOT_COMMANDS
    
    print_warning "Default user: customuser, password: password"
    print_warning "Default root password: root"
    print_warning "CHANGE THESE PASSWORDS IN PRODUCTION!"
}

customize_system() {
    print_info "Applying custom configurations..."
    
    # Create OS release information
    cat > "$ROOT_DIR/etc/os-release" << EOF
NAME="NexaOS"
VERSION="$OS_VERSION"
ID=nexaos
ID_LIKE=debian
PRETTY_NAME="NexaOS $OS_VERSION"
VERSION_ID="$OS_VERSION"
HOME_URL="https://nexuspenn.org"
SUPPORT_URL="https://nexuspenn.org/support"
BUG_REPORT_URL="https://nexuspenn.org/vdp"
LOGO=nexaos
EOF
    
    # Create a welcome message with NexaOS branding
    cat > "$ROOT_DIR/etc/motd" << EOF

\E2\95\94\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\97
\E2\95\91                                                               \E2\95\91
\E2\95\91   \E2\96\88\E2\96\88\E2\96\88\E2\95\97   \E2\96\88\E2\96\88\E2\95\97\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\95\97\E2\96\88\E2\96\88\E2\95\97  \E2\96\88\E2\96\88\E2\95\97 \E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\95\97  \E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\95\97 \E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\95\97       \E2\95\91
\E2\95\91   \E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\95\97  \E2\96\88\E2\96\88\E2\95\91\E2\96\88\E2\96\88\E2\95\94\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\9D\E2\95\9A\E2\96\88\E2\96\88\E2\95\97\E2\96\88\E2\96\88\E2\95\94\E2\95\9D\E2\96\88\E2\96\88\E2\95\94\E2\95\90\E2\95\90\E2\96\88\E2\96\88\E2\95\97\E2\96\88\E2\96\88\E2\95\94\E2\95\90\E2\95\90\E2\95\90\E2\96\88\E2\96\88\E2\95\97\E2\96\88\E2\96\88\E2\95\94\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\9D       \E2\95\91
\E2\95\91   \E2\96\88\E2\96\88\E2\95\94\E2\96\88\E2\96\88\E2\95\97 \E2\96\88\E2\96\88\E2\95\91\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\95\97   \E2\95\9A\E2\96\88\E2\96\88\E2\96\88\E2\95\94\E2\95\9D \E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\95\91\E2\96\88\E2\96\88\E2\95\91   \E2\96\88\E2\96\88\E2\95\91\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\95\97       \E2\95\91
\E2\95\91   \E2\96\88\E2\96\88\E2\95\91\E2\95\9A\E2\96\88\E2\96\88\E2\95\97\E2\96\88\E2\96\88\E2\95\91\E2\96\88\E2\96\88\E2\95\94\E2\95\90\E2\95\90\E2\95\9D   \E2\96\88\E2\96\88\E2\95\94\E2\96\88\E2\96\88\E2\95\97 \E2\96\88\E2\96\88\E2\95\94\E2\95\90\E2\95\90\E2\96\88\E2\96\88\E2\95\91\E2\96\88\E2\96\88\E2\95\91   \E2\96\88\E2\96\88\E2\95\91\E2\95\9A\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\96\88\E2\96\88\E2\95\91       \E2\95\91
\E2\95\91   \E2\96\88\E2\96\88\E2\95\91 \E2\95\9A\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\95\91\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\95\97\E2\96\88\E2\96\88\E2\95\94\E2\95\9D \E2\96\88\E2\96\88\E2\95\97\E2\96\88\E2\96\88\E2\95\91  \E2\96\88\E2\96\88\E2\95\91\E2\95\9A\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\95\94\E2\95\9D\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\95\91       \E2\95\91
\E2\95\91   \E2\95\9A\E2\95\90\E2\95\9D  \E2\95\9A\E2\95\90\E2\95\90\E2\95\90\E2\95\9D\E2\95\9A\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\9D\E2\95\9A\E2\95\90\E2\95\9D  \E2\95\9A\E2\95\90\E2\95\9D\E2\95\9A\E2\95\90\E2\95\9D  \E2\95\9A\E2\95\90\E2\95\9D \E2\95\9A\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\9D \E2\95\9A\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\9D       \E2\95\91
\E2\95\91                                                               \E2\95\91
\E2\95\91   Version $OS_VERSION                                               \E2\95\91
\E2\95\91   A modern Debian-based operating system                     \E2\95\91
\E2\95\91                                                               \E2\95\91
\E2\95\91   Website: https://nexuspenn.org                             \E2\95\91
\E2\95\91   Report Issues: https://nexuspenn.org/                \E2\95\91
\E2\95\91                                                               \E2\95\91
\E2\95\9A\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\9D

EOF

    # Create NexaOS info script
    cat > "$ROOT_DIR/usr/local/bin/nexaos-info" << 'EOF'
#!/bin/bash
echo -e "\033[38;5;99m"
echo "NexaOS System Information"
echo "========================="
echo -e "\033[0m"
echo "OS Name:     NexaOS"
echo "Version:     $(cat /etc/os-release | grep VERSION_ID | cut -d'=' -f2 | tr -d '"')"
echo "Kernel:      $(uname -r)"
echo "Architecture: $(uname -m)"
echo "Hostname:    $(hostname)"
echo ""
echo "Website:     https://nexuspenn.org"
echo "Support:     Kenneth.Daily@nexuspenn.org"
echo "Report Bugs: Kenneth.Daily@nexuspenn.org"
EOF
    chmod +x "$ROOT_DIR/usr/local/bin/nexaos-info"
    
    # Create custom issue file (shown at login prompt)
    cat > "$ROOT_DIR/etc/issue" << EOF
NexaOS $OS_VERSION \\n \\l

EOF

    # Set custom colors for terminal (using NexaOS brand colors)
    cat > "$ROOT_DIR/etc/skel/.bashrc" << 'EOF'
# NexaOS Custom Bash Configuration

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History configuration
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend

# Check window size after each command
shopt -s checkwinsize

# Colored prompt with NexaOS branding
if [ "$color_prompt" = yes ]; then
    PS1='\[\033[38;5;99m\]\u@\h\[\033[00m\]:\[\033[38;5;141m\]\w\[\033[00m\]\$ '
else
    PS1='\u@\h:\w\$ '
fi

# Enable color support
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Useful aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias nexainfo='nexaos-info'

# Welcome message
if [ -f /usr/local/bin/nexaos-info ]; then
    echo ""
fi

EOF
    
    # Copy bashrc to root as well
    cp "$ROOT_DIR/etc/skel/.bashrc" "$ROOT_DIR/root/.bashrc"
}

cleanup_chroot() {
    print_info "Cleaning up chroot environment..."
    
    # Unmount bound filesystems
    umount "$ROOT_DIR/dev/pts" 2>/dev/null || true
    umount "$ROOT_DIR/dev" 2>/dev/null || true
    umount "$ROOT_DIR/proc" 2>/dev/null || true
    umount "$ROOT_DIR/sys" 2>/dev/null || true
}

create_squashfs() {
    print_info "Creating compressed filesystem..."
    mksquashfs "$ROOT_DIR" "$ISO_DIR/live/filesystem.squashfs" -comp xz -e boot
}

setup_bootloader() {
    print_info "Setting up bootloader..."
    
    # Copy kernel and initrd
    cp "$ROOT_DIR"/boot/vmlinuz-* "$ISO_DIR/live/vmlinuz"
    cp "$ROOT_DIR"/boot/initrd.img-* "$ISO_DIR/live/initrd"
    
    # Create GRUB configuration with NexaOS branding
    cat > "$ISO_DIR/boot/grub/grub.cfg" << EOF
set default="0"
set timeout=10

# NexaOS Brand Colors (using closest GRUB color approximations)
set color_normal=white/black
set color_highlight=light-magenta/black

menuentry "NexaOS $OS_VERSION - Live System" {
    linux /live/vmlinuz boot=live components quiet splash
    initrd /live/initrd
}

menuentry "NexaOS $OS_VERSION - Live System (Safe Mode)" {
    linux /live/vmlinuz boot=live components noapic noapm nodma nomce nolapic nomodeset nosmp vga=normal
    initrd /live/initrd
}

menuentry "NexaOS $OS_VERSION - Live System (No Graphics)" {
    linux /live/vmlinuz boot=live components nofb nomodeset vga=normal
    initrd /live/initrd
}

menuentry "Memory Test (memtest86+)" {
    linux16 /live/memtest86+
}
EOF
    
    # Create isolinux configuration for BIOS boot
    cat > "$ISO_DIR/isolinux/isolinux.cfg" << EOF
DEFAULT nexaos
PROMPT 0
TIMEOUT 100

LABEL nexaos
  MENU LABEL NexaOS $OS_VERSION - Live System
  KERNEL /live/vmlinuz
  APPEND initrd=/live/initrd boot=live components quiet splash

LABEL safe
  MENU LABEL NexaOS $OS_VERSION - Safe Mode
  KERNEL /live/vmlinuz
  APPEND initrd=/live/initrd boot=live components noapic noapm nodma nomce nolapic nomodeset nosmp

DISPLAY boot.txt
EOF

    # Create boot splash text
    cat > "$ISO_DIR/isolinux/boot.txt" << EOF

  \E2\96\88\E2\96\88\E2\96\88\E2\95\97   \E2\96\88\E2\96\88\E2\95\97\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\95\97\E2\96\88\E2\96\88\E2\95\97  \E2\96\88\E2\96\88\E2\95\97 \E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\95\97  \E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\95\97 \E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\95\97
  \E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\95\97  \E2\96\88\E2\96\88\E2\95\91\E2\96\88\E2\96\88\E2\95\94\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\9D\E2\95\9A\E2\96\88\E2\96\88\E2\95\97\E2\96\88\E2\96\88\E2\95\94\E2\95\9D\E2\96\88\E2\96\88\E2\95\94\E2\95\90\E2\95\90\E2\96\88\E2\96\88\E2\95\97\E2\96\88\E2\96\88\E2\95\94\E2\95\90\E2\95\90\E2\95\90\E2\96\88\E2\96\88\E2\95\97\E2\96\88\E2\96\88\E2\95\94\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\9D
  \E2\96\88\E2\96\88\E2\95\94\E2\96\88\E2\96\88\E2\95\97 \E2\96\88\E2\96\88\E2\95\91\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\95\97   \E2\95\9A\E2\96\88\E2\96\88\E2\96\88\E2\95\94\E2\95\9D \E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\95\91\E2\96\88\E2\96\88\E2\95\91   \E2\96\88\E2\96\88\E2\95\91\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\95\97
  \E2\96\88\E2\96\88\E2\95\91\E2\95\9A\E2\96\88\E2\96\88\E2\95\97\E2\96\88\E2\96\88\E2\95\91\E2\96\88\E2\96\88\E2\95\94\E2\95\90\E2\95\90\E2\95\9D   \E2\96\88\E2\96\88\E2\95\94\E2\96\88\E2\96\88\E2\95\97 \E2\96\88\E2\96\88\E2\95\94\E2\95\90\E2\95\90\E2\96\88\E2\96\88\E2\95\91\E2\96\88\E2\96\88\E2\95\91   \E2\96\88\E2\96\88\E2\95\91\E2\95\9A\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\96\88\E2\96\88\E2\95\91
  \E2\96\88\E2\96\88\E2\95\91 \E2\95\9A\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\95\91\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\95\97\E2\96\88\E2\96\88\E2\95\94\E2\95\9D \E2\96\88\E2\96\88\E2\95\97\E2\96\88\E2\96\88\E2\95\91  \E2\96\88\E2\96\88\E2\95\91\E2\95\9A\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\95\94\E2\95\9D\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\96\88\E2\95\91
  \E2\95\9A\E2\95\90\E2\95\9D  \E2\95\9A\E2\95\90\E2\95\90\E2\95\90\E2\95\9D\E2\95\9A\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\9D\E2\95\9A\E2\95\90\E2\95\9D  \E2\95\9A\E2\95\90\E2\95\9D\E2\95\9A\E2\95\90\E2\95\9D  \E2\95\9A\E2\95\90\E2\95\9D \E2\95\9A\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\9D \E2\95\9A\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\90\E2\95\9D

  Version $OS_VERSION
  https://nexuspenn.org

Press ENTER to boot, or wait 10 seconds...

EOF
}

create_iso() {
    print_info "Creating bootable ISO image..."
    
    xorriso -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "NEXAOS" \
        -eltorito-boot isolinux/isolinux.bin \
        -eltorito-catalog isolinux/boot.cat \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
        -eltorito-alt-boot \
        -e boot/grub/efi.img \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
        -output "$OUTPUT_ISO" \
        "$ISO_DIR" 2>/dev/null || {
        
        # Fallback for simpler ISO creation
        print_warning "Advanced ISO creation failed, using basic method..."
        grub-mkrescue -o "$OUTPUT_ISO" "$ISO_DIR"
    }
}

################################################################################
# Main Execution
################################################################################

main() {
    print_info "Starting $OS_NAME build process..."
    
    check_root
    check_dependencies
    setup_directories
    install_base_system
    configure_system
    install_packages
    create_user
    customize_system
    cleanup_chroot
    create_squashfs
    setup_bootloader
    create_iso
    
    print_info "Build complete!"
    print_info "ISO file created at: $OUTPUT_ISO"
    print_info "You can now burn this ISO to a USB drive or CD/DVD"
    print_info ""
    print_info "To write to USB (replace /dev/sdX with your USB device):"
    print_info "  dd if=$OUTPUT_ISO of=/dev/sdX bs=4M status=progress && sync"
}

# Run main function
main "$@"