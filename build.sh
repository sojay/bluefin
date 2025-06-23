#!/bin/bash
set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

# Install additional Surface packages not in base image
rpm-ostree install \
    surface-control \
    --allow-inactive

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

# Clean up
dnf clean all
rm -rf /var/cache/dnf/*