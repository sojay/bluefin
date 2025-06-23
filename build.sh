#!/bin/bash
set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

# Configure Surface-specific settings for better hardware support
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
cat > /etc/udev/rules.d/99-surface-pen.rules << 'EOF'
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="091a", TAG+="uaccess"
EOF

# Configure additional Surface device permissions
cat > /etc/udev/rules.d/99-surface-devices.rules << 'EOF'
# Surface cameras
SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="090c", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="0940", TAG+="uaccess"

# Surface SAM
SUBSYSTEM=="misc", KERNEL=="surface_aggregator", MODE="0660", GROUP="input"
SUBSYSTEM=="misc", KERNEL=="surface_aggregator_cdev", MODE="0660", GROUP="input"
EOF

# Create a surface info file
mkdir -p /etc/surface
cat > /etc/surface/device-info << 'EOF'
# Surface Book 2 optimized configuration
# This file indicates Surface-specific optimizations are applied
SURFACE_DEVICE=surface-book-2
SURFACE_CONFIG_VERSION=1.0
EOF

echo "Surface configuration applied successfully"