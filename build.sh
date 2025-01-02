#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

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