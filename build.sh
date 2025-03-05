#!/bin/bash
set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

# Check if running in a container
if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
  echo "Running in a container, skipping /boot checks."
else
  # Ensure /boot is mounted and writable (bare-metal only)
  if ! mount | grep -q "/boot"; then
    echo "/boot is not mounted. Please ensure it is properly configured and mounted."
    exit 1
  fi  # <-- Closes the inner /boot mount check

  if ! touch /boot/testfile 2>/dev/null; then
    echo "/boot is not writable. Please check permissions or mount options."
    exit 1
  fi  # <-- Closes the inner /boot writable check
  rm -f /boot/testfile
fi  # <-- Closes the outer container check

# Add/Overwrite Surface Linux repository (DNF5)
dnf5 config-manager addrepo --overwrite --from-repofile=https://pkg.surfacelinux.com/fedora/linux-surface.repo


# Remove conflicting packages (no sudo)
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

# Install Surface kernel and drivers
dnf5 --disablerepo=updates -y install \
  kernel-surface \
  kernel-surface-core \
  kernel-surface-modules \
  kernel-surface-modules-extra \
  iptsd \
  libwacom-surface \
  --allowerasing


# Install Secure Boot package (optional)
if [[ ! -f /.dockerenv && ! -f /run/.containerenv ]]; then
  dnf5 install -y surface-secureboot
fi


# Clean residual kernel files
KERNEL_VERSION=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel-surface)
find /usr/lib/modules -mindepth 1 -maxdepth 1 -not -name "*${KERNEL_VERSION}*" -exec rm -rf {} +


# Rebuild GRUB config (non-container only)
if [[ ! -f /.dockerenv && ! -f /run/.containerenv ]]; then
  grub2-mkconfig -o /boot/grub2/grub.cfg
  grub2-set-default "Advanced options for Fedora>Fedora, with Linux ${KERNEL_VERSION}"
fi

# Final cleanup
dnf5 clean all
rm -rf /var/cache/dnf/*