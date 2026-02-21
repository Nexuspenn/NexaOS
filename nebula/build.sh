#!/usr/bin/env bash
# =============================================================================
#  NexaOS ISO Build Script — "nebula" profile
#  Target: Debian Bookworm + GNOME + NexaCustomize
#
#  Usage:
#    chmod +x build.sh
#    sudo ./build.sh [--clean] [--arch amd64|arm64] [--jobs N]
#
#  Requirements (install on host before running):
#    sudo apt install live-build debootstrap squashfs-tools xorriso \
#                     grub-pc-bin grub-efi-amd64-bin mtools git python3-pip \
#                     flatpak meson ninja-build gettext libadwaita-1-dev \
#                     libgtk-4-dev glib-compile-schemas
#
#  Output: ./output/NexaOS-nebula-<arch>.iso
# =============================================================================

set -euo pipefail

# ─────────────────────────────────────────────
# Configurable defaults
# ─────────────────────────────────────────────
PROFILE="nebula"
ARCH="${ARCH:-amd64}"
JOBS="${JOBS:-$(nproc)}"
DEBIAN_SUITE="bookworm"
DEBIAN_MIRROR="http://deb.debian.org/debian"
BUILD_DIR="$(pwd)/build-${PROFILE}"
OUTPUT_DIR="$(pwd)/output"
ISO_LABEL="NexaOS-nebula-0.2"
ISO_FILENAME="NexaOS-nebula-0.2-${ARCH}.iso"
DEFAULT_USER="customuser"
DEFAULT_PASS="password"        # hashed below via openssl
HOSTNAME="nexaos"
TIMEZONE="America/New_York"
LOCALE="en_US.UTF-8"

# Repos
NEXAOS_REPO="https://github.com/Nexuspenn/NexaOS.git"
NEXACUSTOMIZE_REPO="https://github.com/Nexuspenn/NexaCustomize.git"

# ─────────────────────────────────────────────
# Colours
# ─────────────────────────────────────────────
RED='\033[0;31m'; GRN='\033[0;32m'; YLW='\033[1;33m'
BLU='\033[0;34m'; CYN='\033[0;36m'; RST='\033[0m'

log()  { echo -e "${BLU}[$(date +%H:%M:%S)] ${GRN}$*${RST}"; }
warn() { echo -e "${BLU}[$(date +%H:%M:%S)] ${YLW}WARN: $*${RST}"; }
die()  { echo -e "${BLU}[$(date +%H:%M:%S)] ${RED}ERROR: $*${RST}" >&2; exit 1; }
step() { echo -e "\n${CYN}━━━ $* ━━━${RST}"; }

# ─────────────────────────────────────────────
# Argument parsing
# ─────────────────────────────────────────────
CLEAN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --clean)   CLEAN=1 ;;
    --arch)    ARCH="$2"; shift ;;
    --jobs)    JOBS="$2"; shift ;;
    --help|-h)
      grep '^#' "$0" | grep -v '#!/' | sed 's/^# \?//'
      exit 0 ;;
    *) die "Unknown argument: $1" ;;
  esac
  shift
done

# ─────────────────────────────────────────────
# Root check
# ─────────────────────────────────────────────
[[ $EUID -eq 0 ]] || die "This script must be run as root (use sudo)."

# ─────────────────────────────────────────────
# Dependency check & auto-install
# ─────────────────────────────────────────────
step "Checking host dependencies"

# Map: command → apt package name
declare -A DEP_MAP=(
  [lb]="live-build"
  [debootstrap]="debootstrap"
  [xorriso]="xorriso"
  [mksquashfs]="squashfs-tools"
  [git]="git"
  [meson]="meson"
  [ninja]="ninja-build"
  [python3]="python3"
  [msgfmt]="gettext"
)

MISSING_PKGS=()
for cmd in "${!DEP_MAP[@]}"; do
  if ! command -v "$cmd" &>/dev/null; then
    warn "Missing command: $cmd  (package: ${DEP_MAP[$cmd]})"
    MISSING_PKGS+=("${DEP_MAP[$cmd]}")
  fi
done

# Extra packages that have no single-command check
EXTRA_PKGS=(
  grub-pc-bin
  grub-efi-amd64-bin
  mtools
  python3-gi
  python3-gi-cairo
  gir1.2-gtk-4.0
  gir1.2-adw-1
  libadwaita-1-dev
  libgtk-4-dev
  glib-compile-schemas
  flatpak
  ca-certificates
)

if [[ ${#MISSING_PKGS[@]} -gt 0 ]] || true; then
  log "Running apt-get update..."
  apt-get update -qq || { warn "apt-get update failed — continuing anyway."; }

  ALL_PKGS=("${MISSING_PKGS[@]}" "${EXTRA_PKGS[@]}")
  # Deduplicate
  readarray -t ALL_PKGS < <(printf '%s\n' "${ALL_PKGS[@]}" | sort -u)

  log "Installing: ${ALL_PKGS[*]}"
  if ! apt-get install -y --no-install-recommends "${ALL_PKGS[@]}"; then
    echo
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
    echo -e "${RED}  Automatic install failed. Run this manually first:${RST}"
    echo
    echo -e "  sudo apt-get update"
    echo -e "  sudo apt-get install -y \\"
    printf '    %s \\\n' "${ALL_PKGS[@]}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
    echo
    die "Dependency installation failed. See instructions above."
  fi
fi

# Final verification
FAILED=()
for cmd in "${!DEP_MAP[@]}"; do
  command -v "$cmd" &>/dev/null || FAILED+=("$cmd")
done
if [[ ${#FAILED[@]} -gt 0 ]]; then
  die "Still missing after install attempt: ${FAILED[*]}"
fi

log "All dependencies satisfied."

# ─────────────────────────────────────────────
# Clean previous build if requested
# ─────────────────────────────────────────────
if [[ $CLEAN -eq 1 ]]; then
  step "Cleaning previous build"
  [[ -d "$BUILD_DIR" ]] && lb clean --purge --build-dir "$BUILD_DIR" 2>/dev/null || true
  rm -rf "$BUILD_DIR"
  log "Clean done."
fi

mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"
cd "$BUILD_DIR"

# ─────────────────────────────────────────────
# STEP 1 — Configure live-build
# ─────────────────────────────────────────────
step "1/8  Configuring live-build"

lb config \
  --architectures        "$ARCH" \
  --distribution         "$DEBIAN_SUITE" \
  --archive-areas        "main contrib non-free non-free-firmware" \
  --mirror-bootstrap     "$DEBIAN_MIRROR" \
  --mirror-chroot        "$DEBIAN_MIRROR" \
  --mirror-binary        "$DEBIAN_MIRROR" \
  --apt-recommends       true \
  --binary-images        iso-hybrid \
  --bootloaders          "grub-efi,grub-pc" \
  --grub-splash          none \
  --iso-application      "NexaOS Nebula 0.2" \
  --iso-preparer         "Nexus Foundation" \
  --iso-publisher        "Nexus Foundation" \
  --iso-volume           "$ISO_LABEL" \
  --memtest              none \
  --hostname             "$HOSTNAME" \
  --image-name           "NexaOS-${PROFILE}-${ARCH}" \
  --color \
  --verbose

log "live-build configured."

# ─────────────────────────────────────────────
# STEP 2 — Package lists
# ─────────────────────────────────────────────
step "2/8  Writing package lists"

# Base system
cat > config/package-lists/base.list.chroot <<'EOF'
# ── Base utilities ──────────────────────────
apt-transport-https
ca-certificates
curl
wget
git
rsync
sudo
bash-completion
man-db
less
vim
nano
htop
lsof
pciutils
usbutils
dnsutils
net-tools
iproute2
network-manager
network-manager-gnome
nftables
openssh-client
unzip
zip
p7zip-full
xz-utils

# ── Locale & timezone ────────────────────────
locales
tzdata
EOF

# GNOME desktop
cat > config/package-lists/gnome.list.chroot <<'EOF'
# ── Display server / Wayland ─────────────────
xorg
xserver-xorg
wayland-protocols
xwayland

# ── GNOME shell & core ───────────────────────
gnome-shell
gnome-shell-extensions
gnome-session
gnome-settings-daemon
gnome-control-center
gnome-tweaks
gnome-backgrounds
gnome-keyring
gnome-screenshot
gnome-software
gnome-disk-utility
gnome-system-monitor
gnome-calculator
gnome-text-editor
gnome-clocks
gnome-weather
gnome-calendar
gnome-maps
gnome-logs
gnome-console

# ── Files & media ────────────────────────────
nautilus
eog
evince
totem
rhythmbox
cheese

# ── GDM3 login manager ───────────────────────
gdm3

# ── Themes & icons ───────────────────────────
papirus-icon-theme
adwaita-icon-theme
adwaita-qt
fonts-cantarell
fonts-jetbrains-mono
fonts-noto
fonts-noto-color-emoji

# ── GTK / libs ───────────────────────────────
libadwaita-1-0
libgtk-4-1
libgtk-3-0
gir1.2-gtk-4.0
gir1.2-adw-1
python3-gi
python3-gi-cairo
gir1.2-gtk-3.0

# ── Flatpak support ──────────────────────────
flatpak
gnome-software-plugin-flatpak

# ── Multimedia codecs ────────────────────────
gstreamer1.0-plugins-base
gstreamer1.0-plugins-good
gstreamer1.0-plugins-bad
gstreamer1.0-plugins-ugly
gstreamer1.0-libav
gstreamer1.0-pulseaudio
libavcodec-extra

# ── Audio ────────────────────────────────────
pulseaudio
pipewire
pipewire-pulse
pavucontrol

# ── Printing ─────────────────────────────────
cups
system-config-printer

# ── Bluetooth ────────────────────────────────
bluetooth
bluez
blueman

# ── Accessibility ────────────────────────────
at-spi2-core
orca
EOF

# Live system tools
cat > config/package-lists/live.list.chroot <<'EOF'
live-boot
live-boot-initramfs-tools
live-config
live-config-systemd
initramfs-tools
EOF

log "Package lists written."

# ─────────────────────────────────────────────
# STEP 3 — Chroot hooks
# ─────────────────────────────────────────────
step "3/8  Writing chroot hooks"
mkdir -p config/hooks/live

# ── 0010 — Locale & timezone
cat > config/hooks/live/0010-locale-timezone.hook.chroot <<HOOK
#!/bin/bash
set -e
echo "${LOCALE} UTF-8" > /etc/locale.gen
locale-gen
update-locale LANG=${LOCALE}
echo "${TIMEZONE}" > /etc/timezone
ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
dpkg-reconfigure -f noninteractive tzdata
HOOK

# ── 0020 — Create default user
HASHED_PASS="$(openssl passwd -6 "${DEFAULT_PASS}")"
cat > config/hooks/live/0020-create-user.hook.chroot <<HOOK
#!/bin/bash
set -e
# Remove any existing user
id "${DEFAULT_USER}" &>/dev/null && userdel -r "${DEFAULT_USER}" 2>/dev/null || true

useradd -m -s /bin/bash \
  -c "NexaOS User" \
  -G sudo,audio,video,cdrom,plugdev,netdev,bluetooth \
  "${DEFAULT_USER}"

echo "${DEFAULT_USER}:${HASHED_PASS}" | chpasswd -e

# Allow sudo without password for live session
echo "${DEFAULT_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/nexaos-live
chmod 0440 /etc/sudoers.d/nexaos-live
HOOK

# ── 0030 — GDM auto-login
cat > config/hooks/live/0030-gdm-autologin.hook.chroot <<HOOK
#!/bin/bash
set -e
mkdir -p /etc/gdm3
cat > /etc/gdm3/custom.conf <<'GDMCONF'
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=${DEFAULT_USER}
TimedLoginEnable=false

[security]
DisallowTCP=false

[xdmcp]

[chooser]

[debug]
GDMCONF
HOOK

# ── 0040 — GNOME default settings via dconf
cat > config/hooks/live/0040-gnome-defaults.hook.chroot <<'HOOK'
#!/bin/bash
set -e

DCONF_DIR="/etc/dconf/db/local.d"
DCONF_LOCKS="/etc/dconf/db/local.d/locks"
mkdir -p "$DCONF_DIR" "$DCONF_LOCKS"

cat > "$DCONF_DIR/01-nexaos-defaults" <<'DCONF'
[org/gnome/desktop/interface]
color-scheme='prefer-dark'
gtk-theme='adw-gtk3-dark'
icon-theme='Papirus-Dark'
font-name='Cantarell 11'
monospace-font-name='JetBrains Mono 11'
document-font-name='Cantarell 11'
cursor-theme='Adwaita'
enable-animations=true
show-battery-percentage=true

[org/gnome/desktop/background]
picture-options='zoom'
primary-color='#1e1e2e'
secondary-color='#1a1a3e'
color-shading-type='vertical'

[org/gnome/desktop/wm/preferences]
button-layout=':minimize,maximize,close'
action-double-click-titlebar='toggle-maximize'
focus-mode='click'

[org/gnome/shell]
favorite-apps=['org.gnome.Nautilus.desktop', 'org.gnome.Console.desktop', 'nexusfoundation.nexaos.customize.desktop', 'org.gnome.Settings.desktop']
disable-user-extensions=false

[org/gnome/settings-daemon/plugins/power]
sleep-inactive-ac-timeout=3600
sleep-inactive-battery-timeout=900

[org/gnome/desktop/session]
idle-delay=uint32 600

[org/gnome/system/location]
enabled=false
DCONF

dconf update
HOOK

# ── 0050 — Install NexaCustomize from source
cat > config/hooks/live/0050-nexacustomize.hook.chroot <<HOOK
#!/bin/bash
set -e

TMP="/tmp/nexacustomize-build"
rm -rf "\$TMP"
git clone --depth=1 "${NEXACUSTOMIZE_REPO}" "\$TMP"
cd "\$TMP"

# Build with meson
mkdir -p _build
meson setup _build --prefix=/usr
ninja -C _build -j${JOBS}
ninja -C _build install

# Register Flatpak if .flatpak bundle exists
if [[ -f nexaos-customize.flatpak ]]; then
  flatpak install --system --noninteractive nexaos-customize.flatpak || true
fi

# Compile gsettings schemas
glib-compile-schemas /usr/share/glib-2.0/schemas/ 2>/dev/null || true

rm -rf "\$TMP"
HOOK

# ── 0060 — Copy NexaOS rootfs overlay
cat > config/hooks/live/0060-rootfs-overlay.hook.chroot <<HOOK
#!/bin/bash
set -e
# The rootfs directory from the NexaOS repo is copied in via the
# includes.chroot mechanism (see config/includes.chroot/).
# This hook finalises permissions.
if [[ -d /etc/nexaos ]]; then
  chmod -R 755 /etc/nexaos
fi
# Apply branding
if [[ -f /etc/nexaos/os-release.fragment ]]; then
  cat /etc/nexaos/os-release.fragment >> /etc/os-release
fi
HOOK

# ── 0070 — GRUB theme & splash branding
cat > config/hooks/live/0070-branding.hook.chroot <<'HOOK'
#!/bin/bash
set -e

# OS-release branding
cat > /etc/os-release <<'OSREL'
PRETTY_NAME="NexaOS Nebula 0.2"
NAME="NexaOS"
VERSION_ID="0.2"
VERSION="0.2 (Nebula)"
ID=nexaos
ID_LIKE=debian
HOME_URL="https://github.com/Nexuspenn/NexaOS"
SUPPORT_URL="https://github.com/Nexuspenn/NexaOS/issues"
BUG_REPORT_URL="https://github.com/Nexuspenn/NexaOS/issues"
ANSI_COLOR="1;35"
LOGO=nexaos-logo
BUILD_ID="nebula-0.2"
VARIANT="Nebula"
VARIANT_ID=nebula
OSREL

# lsb-release
cat > /etc/lsb-release <<'LSB'
DISTRIB_ID=NexaOS
DISTRIB_RELEASE=0.2
DISTRIB_CODENAME=nebula
DISTRIB_DESCRIPTION="NexaOS Nebula 0.2"
LSB

# Hostname
echo "nexaos" > /etc/hostname
cat > /etc/hosts <<'HOSTS'
127.0.0.1  localhost
127.0.1.1  nexaos
::1        localhost ip6-localhost ip6-loopback
HOSTS

# Issue / motd
cat > /etc/issue <<'ISSUE'

 _   _                  ___  ____
| \ | | _____  ____ _  / _ \/ ___|
|  \| |/ _ \ \/ / _` || | | \___ \
| |\  |  __/>  < (_| || |_| |___) |
|_| \_|\___/_/\_\__,_| \___/|____/

NexaOS Nebula 0.2 — Debian-based GNOME Linux
Default login: customuser / password
\l
ISSUE
cp /etc/issue /etc/issue.net

cat > /etc/motd <<'MOTD'
Welcome to NexaOS Nebula 0.2
Built on Debian Bookworm · GNOME Desktop
GitHub: https://github.com/Nexuspenn/NexaOS
MOTD
HOOK

# ── 0080 — System services & cleanup
cat > config/hooks/live/0080-services.hook.chroot <<'HOOK'
#!/bin/bash
set -e

# Enable key services
systemctl enable NetworkManager gdm3 bluetooth cups || true

# Disable unnecessary services in live environment
systemctl disable apt-daily.timer apt-daily-upgrade.timer \
                  man-db.timer e2scrub_all.timer fstrim.timer 2>/dev/null || true

# Remove live-build artefacts that bloat the ISO
apt-get autoremove -y --purge
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
rm -rf /var/tmp/*
find /var/log -type f -name "*.log" -delete 2>/dev/null || true
HOOK

# Make all hooks executable
chmod +x config/hooks/live/*.hook.chroot
log "Chroot hooks written."

# ─────────────────────────────────────────────
# STEP 4 — Include NexaOS rootfs overlay
# ─────────────────────────────────────────────
step "4/8  Cloning NexaOS rootfs overlay"

ROOTFS_DEST="config/includes.chroot"
mkdir -p "$ROOTFS_DEST"

TMP_NEXAOS="/tmp/nexaos-src"
rm -rf "$TMP_NEXAOS"
git clone --depth=1 "$NEXAOS_REPO" "$TMP_NEXAOS"

if [[ -d "$TMP_NEXAOS/rootfs" ]]; then
  log "Copying rootfs overlay..."
  cp -a "$TMP_NEXAOS/rootfs/." "$ROOTFS_DEST/"
else
  warn "No rootfs directory found in NexaOS repo — skipping overlay."
fi
rm -rf "$TMP_NEXAOS"
log "rootfs overlay staged."

# ─────────────────────────────────────────────
# STEP 5 — GRUB configuration
# ─────────────────────────────────────────────
step "5/8  Writing GRUB bootloader config"

mkdir -p config/bootloaders/grub-pc

cat > config/bootloaders/grub-pc/grub.cfg <<'GRUBCFG'
# ── NexaOS GRUB configuration ────────────────
set default=0
set timeout=5
set timeout_style=menu

insmod all_video
insmod gfxterm
set gfxmode=auto
terminal_output gfxterm

# Colours
set color_normal=light-blue/black
set color_highlight=white/light-blue

menuentry "NexaOS Nebula 0.2 (Live)" --class nexaos --class gnu-linux --class gnu --class os {
    linux   /live/vmlinuz boot=live quiet splash \
            noeject hostname=nexaos username=customuser \
            locales=en_US.UTF-8 timezone=America/New_York \
            components
    initrd  /live/initrd.img
}

menuentry "NexaOS Nebula 0.2 (Live, safe graphics)" --class nexaos {
    linux   /live/vmlinuz boot=live quiet splash \
            noeject hostname=nexaos username=customuser \
            locales=en_US.UTF-8 timezone=America/New_York \
            nomodeset components
    initrd  /live/initrd.img
}

menuentry "NexaOS Nebula 0.2 (RAM only)" --class nexaos {
    linux   /live/vmlinuz boot=live quiet splash \
            noeject toram hostname=nexaos username=customuser \
            locales=en_US.UTF-8 timezone=America/New_York \
            components
    initrd  /live/initrd.img
}

menuentry "Memory Test (memtest86+)" --class memtest {
    linux16 /live/memtest86+
}

menuentry "Boot from first hard disk" {
    set root=(hd0)
    chainloader +1
}
GRUBCFG

# EFI GRUB config (same content)
mkdir -p config/bootloaders/grub-efi
cp config/bootloaders/grub-pc/grub.cfg config/bootloaders/grub-efi/grub.cfg

log "GRUB configs written."

# ─────────────────────────────────────────────
# STEP 6 — Binary hooks (post-squashfs, ISO stage)
# ─────────────────────────────────────────────
step "6/8  Writing binary hooks"
mkdir -p config/hooks/normal

cat > config/hooks/normal/0010-iso-meta.hook.binary <<'HOOK'
#!/bin/bash
set -e
# Embed build metadata into the ISO
cat > binary/nexaos-release.txt <<META
NexaOS Nebula 0.2
Build profile  : nebula
Base           : Debian Bookworm (12)
Desktop        : GNOME 44
Architecture   : amd64
Build date     : $(date -u +"%Y-%m-%d %H:%M UTC")
Homepage       : https://github.com/Nexuspenn/NexaOS
META
echo "ISO metadata written."
HOOK

chmod +x config/hooks/normal/*.hook.binary
log "Binary hooks written."

# ─────────────────────────────────────────────
# STEP 7 — Build the ISO
# ─────────────────────────────────────────────
step "7/8  Building ISO (this takes 15–45 min depending on your connection)"

lb build 2>&1 | tee "${OUTPUT_DIR}/build-${PROFILE}.log"

BUILD_EXIT=${PIPESTATUS[0]}
if [[ $BUILD_EXIT -ne 0 ]]; then
  die "live-build failed (exit $BUILD_EXIT). Check ${OUTPUT_DIR}/build-${PROFILE}.log"
fi

log "live-build completed successfully."

# ─────────────────────────────────────────────
# STEP 8 — Rename & finalise ISO
# ─────────────────────────────────────────────
step "8/8  Finalising output"

# live-build names it something like live-image-amd64.hybrid.iso
BUILT_ISO="$(find "$BUILD_DIR" -maxdepth 1 -name "*.iso" | head -n1)"

if [[ -z "$BUILT_ISO" ]]; then
  die "No ISO file found after build. Check the build log."
fi

FINAL_ISO="${OUTPUT_DIR}/${ISO_FILENAME}"
mv "$BUILT_ISO" "$FINAL_ISO"

# Generate SHA256 checksum
sha256sum "$FINAL_ISO" > "${FINAL_ISO}.sha256"

# Print summary
ISO_SIZE=$(du -sh "$FINAL_ISO" | cut -f1)
echo
echo -e "${CYN}╔══════════════════════════════════════════════════╗${RST}"
echo -e "${CYN}║          NexaOS Nebula 0.2 — Build Complete      ║${RST}"
echo -e "${CYN}╠══════════════════════════════════════════════════╣${RST}"
echo -e "${CYN}║${RST}  ISO   : ${GRN}${FINAL_ISO}${RST}"
echo -e "${CYN}║${RST}  Size  : ${ISO_SIZE}"
echo -e "${CYN}║${RST}  SHA256: $(cut -d' ' -f1 "${FINAL_ISO}.sha256")"
echo -e "${CYN}║${RST}  Login : ${DEFAULT_USER} / ${DEFAULT_PASS}"
echo -e "${CYN}╚══════════════════════════════════════════════════╝${RST}"
echo
echo -e "  ${GRN}Flash to USB:${RST}"
echo -e "    sudo dd if=\"${FINAL_ISO}\" of=/dev/sdX bs=4M status=progress oflag=sync"
echo -e "  ${GRN}Or with:${RST}"
echo -e "    sudo cp \"${FINAL_ISO}\" /dev/sdX"
echo
echo -e "  ${YLW}Note: NexaOS is incompatible with Secure Boot.${RST}"
echo -e "  ${YLW}If BitLocker is active, enable Secure Boot first.${RST}"
echo