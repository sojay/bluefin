#!/bin/bash
set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

# Surface kernels are only available up to F41, not F42 yet
# Use F41 kernel even on F42 base
KERNEL_RELEASE="41"

# Pull prebuilt Surface kernel from ublue cache
skopeo copy docker://ghcr.io/ublue-os/surface-kernel:"${KERNEL_RELEASE}" dir:/tmp/kernel-rpms
KERNEL_TARGZ=$(jq -r '.layers[].digest' < /tmp/kernel-rpms/manifest.json | cut -d : -f 2)
tar -xvzf /tmp/kernel-rpms/"$KERNEL_TARGZ" -C /
mv /tmp/rpms/* /tmp/kernel-rpms/ || true

# Reset any existing kernel overrides first
rpm-ostree override reset \
    kernel \
    kernel-core \
    kernel-modules \
    kernel-modules-core \
    kernel-modules-extra \
    kernel-surface \
    kernel-surface-core \
    kernel-surface-modules \
    kernel-surface-modules-core \
    kernel-surface-modules-extra || true

# Remove existing kernel packages
REMOVE_LIST=(
  kernel
  kernel-core
  kernel-modules
  kernel-modules-core
  kernel-modules-extra
)

for pkg in "${REMOVE_LIST[@]}"; do
  rpm --erase $pkg --nodeps || true
done

# Replace kernel with Surface kernel using rpm-ostree
rpm-ostree override replace \
    --experimental \
        /tmp/kernel-rpms/kernel-surface-*.rpm \
        /tmp/kernel-rpms/kernel-surface-core-*.rpm \
        /tmp/kernel-rpms/kernel-surface-modules-*.rpm \
        /tmp/kernel-rpms/kernel-surface-modules-core-*.rpm \
        /tmp/kernel-rpms/kernel-surface-modules-extra-*.rpm

# Install Surface-specific packages
rpm-ostree install --allow-inactive \
    /tmp/kernel-rpms/iptsd-*.rpm \
    /tmp/kernel-rpms/libwacom-surface-*.rpm \
    /tmp/kernel-rpms/libwacom-surface-data-*.rpm

if [[ $SUFFIX == *"dx"* ]]; then
  # Reset devel package overrides if they exist
  rpm-ostree override reset kernel-devel kernel-devel-matched kernel-surface-devel kernel-surface-devel-matched || true
  
  rpm-ostree override replace --experimental \
      /tmp/kernel-rpms/kernel-surface-devel-*.rpm \
      /tmp/kernel-rpms/kernel-surface-devel-matched-*.rpm
fi

# Find the installed kernel version
QUALIFIED_KERNEL="$(rpm -qa | grep -P 'kernel-surface-(\d+)' | sed -E 's/kernel-surface-//')"

# Rebuild initramfs for the Surface kernel
/usr/libexec/rpm-ostree/wrapped/dracut \
    --no-hostonly \
    --kver "$QUALIFIED_KERNEL" \
    --reproducible \
    --zstd \
    -v \
    --add ostree \
    -f "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"

chmod 0600 /lib/modules/$QUALIFIED_KERNEL/initramfs.img

# Cleanup
rm -rf /tmp/kernel-rpms

