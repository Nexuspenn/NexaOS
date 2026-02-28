#!/bin/bash

################################################################################
# NexaOS - Nexus Foundation Whistleblower Edition (Official Master Build)
# Features: Amnesic, Tor-Only, Hardened, Isolated, Verified, Comprehensive Sources
################################################################################

set -e

# Configuration
OS_NAME="NexaOS"
OS_VERSION="0.2-Nebula"
DEBIAN_RELEASE="bookworm"
BUILD_DIR="/tmp/nexaos-build"
ROOT_DIR="${BUILD_DIR}/rootfs"
ISO_DIR="${BUILD_DIR}/iso"
OUTPUT_ISO="${BUILD_DIR}/NexaOS-Nexus-Final.iso"

# Styling
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

print_nexus() { echo -e "${BLUE}[NEXUS-INIT]${NC} $1"; }

check_root() { [[ "$EUID" -ne 0 ]] && echo "Error: Must run as root." && exit 1; }

setup_env() {
    print_nexus "Initializing Nexus Build Environment..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$ROOT_DIR" "$ISO_DIR"/{live,boot/grub}
}

install_core() {
    print_nexus "Bootstrapping Debian Core..."
    apt-get update && apt-get install -y debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools
    debootstrap --arch=amd64 "$DEBIAN_RELEASE" "$ROOT_DIR" http://deb.debian.org/debian/
}

install_packages() {
    print_nexus "Injecting Hardened Security Stack..."
    mount --bind /dev "$ROOT_DIR/dev"
    mount --bind /dev/pts "$ROOT_DIR/dev/pts"
    mount --bind /proc "$ROOT_DIR/proc"
    mount --bind /sys "$ROOT_DIR/sys"
    cp /etc/resolv.conf "$ROOT_DIR/etc/resolv.conf"

    chroot "$ROOT_DIR" /bin/bash << 'CHROOT_CMDS'
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y linux-image-amd64 live-boot systemd-sysv \
    tor torbrowser-launcher nftables firejail apparmor apparmor-profiles \
    network-manager secure-delete mat2 sudo curl xfce4 xfce4-terminal \
    lightdm plymouth plymouth-themes firmware-linux-free

systemctl enable tor nftables apparmor
firecfg
apt-get clean
CHROOT_CMDS
}

customize_nexus() {
    print_nexus "Applying Nexus Identity, Global Portal & Killswitches..."

    # 1. Branding (MotD)
    cat > "$ROOT_DIR/etc/motd" << 'EOF'
    _   __              ____  _____
   / | / /__ _  ______ / __ \/ ___/
  /  |/ / _ \ |/_/ __ `/ / / /\__ \ 
 / /|  /  __/>  < /_/ / /_/ /___/ / 
/_/ |_/\___/_/|_|\__,_/\____//____/  
NexaOS: Nexus Foundation Whistleblower Edition
Security: [AMNESIC] [TOR-ENFORCED] [SANDBOXED]
EOF

    # 2. Tor-Only Firewall
    cat > "$ROOT_DIR/etc/nftables.conf" << 'EOF'
flush ruleset
table inet filter {
    chain input { type filter hook input priority 0; policy drop; iif "lo" accept; ct state established,related accept; }
    chain output { type filter hook output priority 0; policy drop; oif "lo" accept; skuid "debian-tor" accept; }
}
EOF

    # 3. GLOBAL PORTAL HTML (Comprehensive Sources)
    mkdir -p "$ROOT_DIR/var/lib/nexa"
    cat > "$ROOT_DIR/var/lib/nexa/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>NexaOS - Whistleblower Edition</title>
    <style>
        body { font-family: sans-serif; background: #0f121b; color: #f6f6f6; margin: 0; padding: 20px; }
        .hero { text-align: center; padding: 20px; border-bottom: 1px solid rgba(255,255,255,0.1); }
        h1 { font-size: 2.5rem; background: linear-gradient(135deg, #3b82f6, #a855f7); -webkit-background-clip: text; -webkit-text-fill-color: transparent; margin: 10px 0; }
        .status { background: #12141d; padding: 15px; border-radius: 8px; margin: 15px 0; border: 1px solid #4f46e5; font-size: 0.9em; text-align: center; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 15px; }
        .card { background: #12141d; padding: 15px; border-radius: 8px; border: 1px solid rgba(255,255,255,0.05); }
        .btn { display: inline-block; background: #4f46e5; color: white; padding: 8px 16px; border-radius: 6px; text-decoration: none; margin-top: 10px; font-weight: bold; font-size: 0.8em; }
        h3 { margin-top: 0; color: #3b82f6; }
        p { font-size: 0.85em; opacity: 0.8; }
    </style>
</head>
<body>
    <div class="hero">
        <h1>NexaOS Portal</h1>
        <p>Verified Secure Submission Directory</p>
    </div>
    <div class="status">
        <strong>SECURITY MODE:</strong> AMNESIC (RAM-ONLY) | <strong>NETWORK:</strong> TOR CIRCUIT ENFORCED
    </div>
    <div class="grid">
        <div class="card">
            <h3>Associated Press</h3>
            <p>Global news network for high-impact evidence.</p>
            <a href="http://3p76br67vls7fdvntvsnj3jndy62ks5v5cn4n6nva3i6472f7v2noad.onion/" class="btn">SECUREDROP</a>
        </div>
        <div class="card">
            <h3>WikiLeaks</h3>
            <p>Original source for large-scale data leaks.</p>
            <a href="http://v6u7onv3sh3fxf65.onion/" class="btn">WIKILEAKS</a>
        </div>
        <div class="card">
            <h3>The New York Times</h3>
            <p>US-based investigative reporting desk.</p>
            <a href="http://ej3kv43zy2u4u745.onion/" class="btn">SECUREDROP</a>
        </div>
        <div class="card">
            <h3>The Guardian</h3>
            <p>UK-based platform for international leaks.</p>
            <a href="http://33y6fjyxt3rrid6y.onion/" class="btn">SECUREDROP</a>
        </div>
        <div class="card">
            <h3>ProPublica</h3>
            <p>Dedicated to investigative journalism in the public interest.</p>
            <a href="http://p5364fe3bd5gs7qyz7iwicbfbu6u7vpl76ws6uevsh6clv7fgeucl6id.onion/" class="btn">SECUREDROP</a>
        </div>
        <div class="card">
            <h3>SecureDrop Directory</h3>
            <p>A list of over 70 worldwide media outlets using SecureDrop.</p>
            <a href="http://sdrop3vsu7yqfxtp.onion/" class="btn">FULL DIRECTORY</a>
        </div>
    </div>
</body>
</html>
EOF

    # 4. Utilities
    cat > "$ROOT_DIR/usr/local/bin/self-destruct" << 'EOF'
#!/bin/bash
sync && sdmem -f -ll
echo o > /proc/sys/kernel/sysrq
EOF
    chmod +x "$ROOT_DIR/usr/local/bin/self-destruct"

    cat > "$ROOT_DIR/usr/local/bin/nexa-init" << 'EOF'
#!/bin/bash
until curl --socks5-hostname 127.0.0.1:9050 -sI https://check.torproject.org | grep -q "Congratulations"; do sleep 2; done
torbrowser-launcher file:///var/lib/nexa/index.html
EOF
    chmod +x "$ROOT_DIR/usr/local/bin/nexa-init"

    mkdir -p "$ROOT_DIR/etc/skel/.config/autostart"
    cat > "$ROOT_DIR/etc/skel/.config/autostart/nexa.desktop" << EOF
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/nexa-init
EOF
}

build_iso() {
    print_nexus "Generating Bootable ISO..."
    mksquashfs "$ROOT_DIR" "$ISO_DIR/live/filesystem.squashfs" -comp xz
    cp "$ROOT_DIR"/boot/vmlinuz-* "$ISO_DIR/live/vmlinuz"
    cp "$ROOT_DIR"/boot/initrd.img-* "$ISO_DIR/live/initrd"
    cat > "$ISO_DIR/boot/grub/grub.cfg" << EOF
set timeout=1
menuentry "NexaOS [Nexus Foundation]" {
    linux /live/vmlinuz boot=live quiet splash
    initrd /live/initrd
}
EOF
    grub-mkrescue -o "$OUTPUT_ISO" "$ISO_DIR"
}

generate_manifest() {
    sha256sum "$OUTPUT_ISO" > "${OUTPUT_ISO}.sha256.txt"
}

cleanup() {
    umount -lf "$ROOT_DIR/dev/pts" || true
    umount -lf "$ROOT_DIR/dev" || true
    umount -lf "$ROOT_DIR/proc" || true
    umount -lf "$ROOT_DIR/sys" || true
}

check_root
setup_env
install_core
install_packages
customize_nexus
cleanup
build_iso
generate_manifest
print_nexus "DONE. ISO PRODUCED AT $BUILD_DIR"
