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

# Add Surface Linux repository
if [[ ! -f /etc/yum.repos.d/linux-surface.repo ]]; then
  curl -LO https://pkg.surfacelinux.com/fedora/linux-surface.repo
  mv linux-surface.repo /etc/yum.repos.d/
  dnf clean all
fi

# Remove conflicting kernel packages
REMOVE_LIST=(
  kmod-openrazer
  kmod-v4l2loopback
  kmod-xone
  kernel
  kernel-core
  kernel-modules
  kernel-modules-extra
)

for pkg in "${REMOVE_LIST[@]}"; do
  if rpm -q "$pkg"; then
    dnf remove -y "$pkg" || echo "Failed to remove $pkg. Skipping..."
  fi
done

# Install the Surface kernel
dnf install -y \
  kernel-surface \
  kernel-surface-core \
  kernel-surface-modules \
  kernel-surface-modules-extra

# Set the Surface kernel as the default
KERNEL_VERSION=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel-surface | head -n 1)
if [[ -z "$KERNEL_VERSION" ]]; then
  echo "Failed to install the Surface kernel."
  exit 1
fi

if [[ ! -f /.dockerenv && ! -f /run/.containerenv ]]; then
  grub2-set-default "Advanced options for Fedora>Fedora, with Linux $KERNEL_VERSION"
  grub2-mkconfig -o /boot/grub2/grub.cfg
fi

# Reboot the system
if [[ ! -f /.dockerenv && ! -f /run/.containerenv ]]; then
  echo "Rebooting to apply the Surface kernel..."
  reboot
else
  echo "Running in a container, skipping reboot."
fi