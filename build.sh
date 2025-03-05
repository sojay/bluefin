#!/bin/bash
set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

# Check if running in a container
if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
  echo "Running in a container, skipping /boot checks."
else
  # Ensure /boot is mounted and writable
  if ! mount | grep -q "/boot"; then
    echo "/boot is not mounted. Please ensure it is properly configured and mounted."
    exit 1
  fi

  if ! touch /boot/testfile 2>/dev/null; then
    echo "/boot is not writable. Please check permissions or mount options."
    exit 1
  fi
  rm -f /boot/testfile
fi

# Create grubenv if missing
if [[ ! -f /boot/grub2/grubenv ]]; then
  mkdir -p /boot/grub2
  grub2-editenv /boot/grub2/grubenv create
fi

# Add Surface Linux repository (DNF5-compatible method)
if [[ ! -f /etc/yum.repos.d/linux-surface.repo ]]; then
  dnf5 config-manager addrepo --from-repofile=https://pkg.surfacelinux.com/fedora/linux-surface.repo
fi

# Remove conflicting packages and install Surface components
dnf5 --disablerepo=updates -y install \
  --allowerasing \
  kernel-surface \
  iptsd \
  libwacom-surface

# Install Secure Boot components if needed
if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
  echo "Skipping Secure Boot setup in container."
else
  dnf5 install -y surface-secureboot
fi

# Cleanup and rebuild GRUB config
if [[ ! -f /.dockerenv && ! -f /run/.containerenv ]]; then
  grub2-mkconfig -o /boot/grub2/grub.cfg
fi

# Set default kernel
KERNEL_VERSION=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel-surface | head -n 1)
grub2-set-default "Advanced options for Fedora>Fedora, with Linux $KERNEL_VERSION"

# Reboot if not in container
if [[ ! -f /.dockerenv && ! -f /run/.containerenv ]]; then
  echo "Rebooting to apply changes..."
  reboot
else
  echo "Container build complete."
fi