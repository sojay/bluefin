#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

# Add Repos
RUN dnf5 config-manager addrepo --from-repofile=https://pkg.surfacelinux.com/fedora/linux-surface.repo

dnf5 -y install --allowerasing \
  kernel-surface \
  iptsd \
  libwacom-surface \
  # kernel-$KERNEL_VERSION \
  # kernel-core-$KERNEL_VERSION \
  # kernel-devel-$KERNEL_VERSION \
  # kernel-devel-matched-$KERNEL_VERSION \
  # kernel-modules-$KERNEL_VERSION \
  # kernel-modules-core-$KERNEL_VERSION \
  # kernel-modules-extra-$KERNEL_VERSION \
  # kernel-tools-$KERNEL_VERSION \
  # kernel-tools-libs-$KERNEL_VERSION \
  # kernel-uki-virt-$KERNEL_VERSION \
  # kernel-uki-virt-addons-$KERNEL_VERSION \

dnf5 -y copr enable ublue-os/staging
dnf5 -y copr enable ublue-os/akmods

skopeo copy docker://ghcr.io/ublue-os/akmods-extra:surface-"${RELEASE}" dir:/tmp/akmods-extra-rpms
AKMODS_EXTRA_TARGZ=$(jq -r '.layers[].digest' < /tmp/akmods-extra-rpms/manifest.json | cut -d : -f 2)
tar -xvzf /tmp/akmods-extra-rpms/"$AKMODS_EXTRA_TARGZ" -C /tmp/
mv /tmp/rpms/* /tmp/akmods-extra-rpms/


if [[ $SUFFIX == *"nvidia"* ]]; then
  skopeo copy docker://ghcr.io/ublue-os/akmods-nvidia-open:surface-"${RELEASE}" dir:/tmp/akmods-nvidia-open-rpms
  AKMODS_NVIDIA_OPEN_TARGZ=$(jq -r '.layers[].digest' < /tmp/akmods-nvidia-open-rpms/manifest.json | cut -d : -f 2)
  tar -xvzf /tmp/akmods-nvidia-open-rpms/"$AKMODS_NVIDIA_OPEN_TARGZ" -C /tmp/
  mv /tmp/rpms/* /tmp/akmods-nvidia-open-rpms/

  rpm --erase kmod-nvidia --nodeps ; 
fi

### Install packages
rpm-ostree install screen

#### Example for enabling a System Unit File
systemctl enable podman.socket

### Update Bootloader (Silverblue/Atomic Host Specific)
if [[ -d /usr/lib/ostree-boot/efi/EFI ]]; then
  echo "Updating bootloader files..."

  # Backup the existing EFI partition content
  mkdir -p /boot/efi/EFI.bkp
  cp -a /boot/efi/EFI /boot/efi/EFI.bkp

  # Copy updated bootloader versions
  cp /usr/lib/ostree-boot/efi/EFI/BOOT/{BOOTIA32.EFI,BOOTX64.EFI,fbia32.efi,fbx64.efi} /boot/efi/EFI/BOOT/
  cp /usr/lib/ostree-boot/efi/EFI/fedora/{BOOTIA32.CSV,BOOTX64.CSV,grubia32.efi,grubx64.efi,mmia32.efi,mmx64.efi,shim.efi,shimia32.efi,shimx64.efi} /boot/efi/EFI/fedora/

  # Handle specific shim file, if present
  if [[ -f /usr/lib/ostree-boot/efi/EFI/fedora/shimx64.efi ]]; then
    cp /usr/lib/ostree-boot/efi/EFI/fedora/shimx64.efi /boot/efi/EFI/fedora/shimx64-fedora.efi
  fi

  # Sync changes to the disk
  sync
  echo "Bootloader update completed."
fi
