#!/bin/bash
################################################################################
# NexaOS First Boot Setup
# This script runs automatically on first boot to configure the system
################################################################################

SETUP_FLAG="/var/lib/nexaos/.first-boot-complete"

# Check if already run
if [ -f "$SETUP_FLAG" ]; then
    exit 0
fi

# Ensure we're running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root during first boot"
    exit 1
fi

# Run the installer
/usr/local/bin/nexaos-installer.sh

# Mark as complete
mkdir -p /var/lib/nexaos
touch "$SETUP_FLAG"
