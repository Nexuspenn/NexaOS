#!/bin/bash

# NexaOS Build Script - Interactive GUI, Boot Logo, Custom Wallpaper, and Brand Theming
set -e

################################################################################
# Variables
################################################################################
OS_NAME="NexaOS"
OS_VERSION="0.2"
DEBIAN_RELEASE="bookworm"
ARCH="amd64"  # Options: amd64, i386, arm64, armhf
BUILD_DIR="$(pwd)/build"
ROOT_DIR="$BUILD_DIR/chroot"
ISO_DIR="$BUILD_DIR/iso"
OUTPUT_ISO="NexaOS-$OS_VERSION-amd64.iso"
LOGO_URL="https://nexuspenn.org/favicon.ico"
WALLPAPER_URL="https://nexuspenn.org/wallpaper.png"

# Brand Colors (Purple/Violet Accents)
BRAND_COLOR="#6200EA"

################################################################################
# Helper Functions
################################################################################

print_info() { echo -e "\e[34m[INFO]\e[0m $1"; }
print_warning() { echo -e "\e[33m[WARNING]\e[0m $1"; }
print_error() { echo -e "\e[31m[ERROR]\e[0m $1"; exit 1; }

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run as root"
    fi
}

select_gui() {
    echo "--------------------------------------"
    echo "      NexaOS Desktop Selector         "
    echo "--------------------------------------"
    echo "1) XFCE (Lightweight & Stable)"
    echo "2) GNOME (Modern & Polished)"
    echo "3) KDE Plasma (Powerful & Visual)"
    echo "4) LXQt (Ultra-lightweight)"
    echo "--------------------------------------"
    read -p "Choose your desktop [1-4]: " gui_choice

    case $gui_choice in
        1) GUI_PKGS="xfce4 xfce4-goodies lightdm lightdm-gtk-greeter-settings"; DESKTOP_NAME="XFCE" ;;
        2) GUI_PKGS="task-gnome-desktop gdm3"; DESKTOP_NAME="GNOME" ;;
        3) GUI_PKGS="task-kde-desktop sddm"; DESKTOP_NAME="KDE" ;;
        4) GUI_PKGS="lxqt sddm"; DESKTOP_NAME="LXQt" ;;
        *) print_error "Invalid selection." ;;
    esac
}

check_dependencies() {
    print_info "Checking host dependencies..."
    local deps="debootstrap arch-install-scripts squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools isolinux syslinux-common imagemagick curl"
    local missing=""
    for dep in $deps; do
        if ! dpkg -l | grep -q "^ii  $dep"; then missing="$missing $dep"; fi
    done
    if [ -n "$missing" ]; then
        apt-get update && apt-get install -y $missing
    fi
}

setup_directories() {
    print_info "Preparing workspace..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$ROOT_DIR"
    mkdir -p "$ISO_DIR"/{live,isolinux,boot/grub}
}

install_base_system() {
    print_info "Debootstrapping base system..."
    debootstrap --arch="$ARCH" "$DEBIAN_RELEASE" "$ROOT_DIR" http://deb.debian.org/debian/
}

install_packages() {
    print_info "Installing $DESKTOP_NAME, Branding, and Themes..."
    
    mount --bind /dev "$ROOT_DIR/dev"
    mount --bind /dev/pts "$ROOT_DIR/dev/pts"
    mount --bind /proc "$ROOT_DIR/proc"
    mount --bind /sys "$ROOT_DIR/sys"
    cp /etc/resolv.conf "$ROOT_DIR/etc/resolv.conf"

    chroot "$ROOT_DIR" /bin/bash << CHROOT_COMMANDS
export DEBIAN_FRONTEND=noninteractive
apt-get update
# Core & Live
apt-get install -y linux-image-amd64 live-boot systemd-sysv sudo plymouth plymouth-themes
# GUI & Installer
apt-get install -y $GUI_PKGS calamares calamares-settings-debian partitionmanager
# Theming: Papirus is a great icon set that fits NexaOS colors well
apt-get install -y papirus-icon-theme arc-theme
# Tools
apt-get install -y vim nano curl wget git htop net-tools ca-certificates wpasupplicant network-manager
apt-get clean
rm -rf /var/lib/apt/lists/*
CHROOT_COMMANDS
}

configure_branding() {
    print_info "Applying NexaOS Branding (Splash, Wallpaper, Themes)..."
    
    # 1. Boot Logo (Plymouth)
    curl -sL "$LOGO_URL" -o "$BUILD_DIR/nexaos_icon.ico"
    convert "$BUILD_DIR/nexaos_icon.ico[0]" -resize 256x256 "$ROOT_DIR/usr/share/plymouth/themes/spinner/watermark.png"
    chroot "$ROOT_DIR" plymouth-set-default-theme -R spinner

    # 2. Wallpaper
    mkdir -p "$ROOT_DIR/usr/share/backgrounds/nexaos"
    curl -sL "$WALLPAPER_URL" -o "$ROOT_DIR/usr/share/backgrounds/nexaos/nexaos-wallpaper.png"

    # 3. GUI Specific Theming (XFCE)
    if [ "$DESKTOP_NAME" == "XFCE" ]; then
        mkdir -p "$ROOT_DIR/etc/xdg/xfce4/xfconf/xfce-perchannel-xml"
        # Set Wallpaper, Theme (Arc-Dark), and Icons (Papirus)
        cat > "$ROOT_DIR/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Arc-Darker"/>
    <property name="IconThemeName" type="string" value="Papirus-Dark"/>
  </property>
</channel>
EOF
        cat > "$ROOT_DIR/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="image-path" type="string" value="/usr/share/backgrounds/nexaos/nexaos-wallpaper.png"/>
      </property>
    </property>
  </property>
</channel>
EOF
    fi

    # 4. Login Screen (LightDM) Branding
    if [ -f "$ROOT_DIR/etc/lightdm/lightdm-gtk-greeter.conf" ]; then
        cat > "$ROOT_DIR/etc/lightdm/lightdm-gtk-greeter.conf" << EOF
[greeter]
background=/usr/share/backgrounds/nexaos/nexaos-wallpaper.png
theme-name=Arc-Darker
icon-theme-name=Papirus-Dark
webkit-theme=nexaos
EOF
    fi
}

configure_os_details() {
    print_info "Customizing NexaOS details..."
    mkdir -p "$ROOT_DIR/etc/skel/Desktop"
    cat > "$ROOT_DIR/etc/skel/Desktop/install-nexaos.desktop" << EOF
[Desktop Entry]
Name=Install NexaOS
Comment=Permanent Installation
Exec=sudo calamares
Icon=system-software-install
Terminal=false
Type=Application
EOF
    chmod +x "$ROOT_DIR/etc/skel/Desktop/install-nexaos.desktop"
    echo "NexaOS" > "$ROOT_DIR/etc/hostname"
}

create_user() {
    print_info "Setting up live user..."
    chroot "$ROOT_DIR" /bin/bash << 'CHROOT_COMMANDS'
useradd -m -s /bin/bash -G sudo nexauser
echo "nexauser:live" | chpasswd
echo "nexauser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/nexauser
mkdir -p /home/nexauser/Desktop
cp /etc/skel/Desktop/*.desktop /home/nexauser/Desktop/ || true
chown -R nexauser:nexauser /home/nexauser
CHROOT_COMMANDS
}

cleanup_chroot() {
    print_info "Unmounting..."
    umount "$ROOT_DIR/dev/pts" 2>/dev/null || true
    umount "$ROOT_DIR/dev" 2>/dev/null || true
    umount "$ROOT_DIR/proc" 2>/dev/null || true
    umount "$ROOT_DIR/sys" 2>/dev/null || true
}

create_squashfs() {
    print_info "Creating compressed system (SquashFS)..."
    mksquashfs "$ROOT_DIR" "$ISO_DIR/live/filesystem.squashfs" -comp xz -e boot
}

setup_bootloader() {
    print_info "Finalizing bootloader..."
    cp "$ROOT_DIR"/boot/vmlinuz-* "$ISO_DIR/live/vmlinuz"
    cp "$ROOT_DIR"/boot/initrd.img-* "$ISO_DIR/live/initrd"
    
    cat > "$ISO_DIR/boot/grub/grub.cfg" << EOF
set default="0"
set timeout=5
set menu_color_normal=white/black
set menu_color_highlight=magenta/black

menuentry "NexaOS $OS_VERSION Live ($DESKTOP_NAME)" {
    linux /live/vmlinuz boot=live components quiet splash plymouth.ignore-serial-consoles ---
    initrd /live/initrd
}
menuentry "NexaOS $OS_VERSION Direct Installer" {
    linux /live/vmlinuz boot=live components quiet splash calamares ---
    initrd /live/initrd
}
EOF

    cp /usr/lib/ISOLINUX/isolinux.bin "$ISO_DIR/isolinux/"
    cp /usr/lib/syslinux/modules/bios/* "$ISO_DIR/isolinux/" 2>/dev/null || true
    cat > "$ISO_DIR/isolinux/isolinux.cfg" << EOF
DEFAULT nexaos
LABEL nexaos
  KERNEL /live/vmlinuz
  APPEND initrd=/live/initrd boot=live components quiet splash plymouth.ignore-serial-consoles ---
EOF
}

create_iso() {
    print_info "Building NexaOS ISO..."
    xorriso -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "NEXAOS" \
        -eltorito-boot isolinux/isolinux.bin \
        -eltorito-catalog isolinux/boot.cat \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
        -output "$OUTPUT_ISO" \
        "$ISO_DIR"
}

main() {
    check_root
    select_gui
    check_dependencies
    setup_directories
    install_base_system
    install_packages
    configure_branding
    configure_os_details
    create_user
    cleanup_chroot
    create_squashfs
    setup_bootloader
    create_iso
    print_info "Build Complete! NexaOS ISO: $OUTPUT_ISO"
}

main "$@"
