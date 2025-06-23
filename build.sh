#!/bin/bash
set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

# Configure Surface-specific settings
mkdir -p /etc/systemd/sleep.conf.d
cat > /etc/systemd/sleep.conf.d/surface.conf << 'EOF'
[Sleep]
HibernateMode=platform shutdown
SuspendState=deep
EOF

# Configure Surface IPTS touchscreen permissions
mkdir -p /etc/udev/rules.d
cat > /etc/udev/rules.d/99-surface-ipts.rules << 'EOF'
SUBSYSTEM=="misc", KERNEL=="ipts/*", MODE="0660", GROUP="input"
EOF

# Configure Surface Pen settings
mkdir -p /etc/udev/rules.d
cat > /etc/udev/rules.d/99-surface-pen.rules << 'EOF'
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="091a", TAG+="uaccess"
EOF

# Clean up
dnf clean all
rm -rf /var/cache/dnf/*