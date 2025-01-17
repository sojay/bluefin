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


REMOVE_LIST=(
  kmod-openrazer
  kmod-v4l2loopback
  kmod-xone
  kernel
  kernel-core
  kernel-modules
  kernel-modules-core
  kernel-modules-extra
)

INSTALL_LIST=(
  /tmp/akmods-rpms/kmods/*xone*.rpm
  /tmp/akmods-rpms/kmods/*openrazer*.rpm
  /tmp/akmods-rpms/kmods/*v4l2loopback*.rpm
  /tmp/akmods-rpms/kmods/*wl*.rpm
  /tmp/akmods-extra-rpms/kmods/*gcadapter_oc*.rpm
  /tmp/akmods-extra-rpms/kmods/*nct6687*.rpm
  /tmp/akmods-extra-rpms/kmods/*vhba*.rpm
  /tmp/akmods-extra-rpms/kmods/*bmi260*.rpm
  /tmp/akmods-extra-rpms/kmods/*ryzen-smu*.rpm
  #/tmp/akmods-extra-rpms/kmods/*evdi*.rpm
  #/tmp/akmods-extra-rpms/kmods/*zenergy*.rpm \
)

REMOVE_LIST_DX=(
  kmod-kvmfr
  kernel-devel
  kernel-devel-matched
)

INSTALL_LIST_DX=(
  /tmp/akmods-rpms/kmods/*kvmfr*.rpm
)

# Install Kernel
KERNEL_VERSION=$(dnf5 list --showduplicates kernel --quiet | grep "x86_64" | grep rog | awk '{print $2}')
if [[ $SUFFIX == *"dx"* ]]; then
  for pkg in "${REMOVE_LIST_DX[@]}" "${REMOVE_LIST[@]}"; do
    rpm --erase $pkg --nodeps ; 
  done
else
  for pkg in "${REMOVE_LIST[@]}"; do
    rpm --erase $pkg --nodeps ; 
  done
fi

# Replace kernel with rpm-ostree
rpm-ostree override replace \
    --experimental \
        /tmp/kernel-rpms/kernel-[0-9]*.rpm \
        /tmp/kernel-rpms/kernel-core-*.rpm \
        /tmp/kernel-rpms/kernel-modules-*.rpm \
        /tmp/kernel-rpms/kernel-uki-virt-*.rpm

if [[ $SUFFIX == *"dx"* ]]; then
  rpm-ostree override replace --experimental /tmp/kernel-rpms/kernel-devel-*.rpm
  rpm-ostree override replace --experimental "${INSTALL_LIST[@]}" "${INSTALL_LIST_DX[@]}"
else
  rpm-ostree override replace --experimental "${INSTALL_LIST[@]}"
fi

if [[ $SUFFIX == *"nvidia"* ]]; then
  rpm-ostree override replace --experimental \
    /tmp/akmods-nvidia-open-rpms/kmods/*nvidia*.rpm
fi


# rpm-ostree override remove \
#   kernel \
#   kernel-core \
#   kernel-modules \
#   kernel-modules-core \
#   kernel-modules-extra \
#   kernel-tools \
#   kernel-tools-libs \
#   kernel-devel-matched \
#   kernel-devel \
#   kmod-framework-laptop \
#   --install kernel-$KERNEL_VERSION \
#   --install kernel-core-$KERNEL_VERSION \
#   --install kernel-devel-$KERNEL_VERSION \
#   --install kernel-devel-matched-$KERNEL_VERSION \
#   --install kernel-modules-$KERNEL_VERSION \
#   --install kernel-modules-core-$KERNEL_VERSION \
#   --install kernel-modules-extra-$KERNEL_VERSION \
#   --install kernel-tools-$KERNEL_VERSION \
#   --install kernel-tools-libs-$KERNEL_VERSION \
#   --install kernel-uki-virt-$KERNEL_VERSION \
#   --install kernel-uki-virt-addons-$KERNEL_VERSION

dnf5 -y install --allowerasing \
  asusctl \
  asusctl-rog-gui
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

# Install Firmware
git clone https://gitlab.com/asus-linux/firmware.git --depth 1 /tmp/asus-firmware
cp -rf /tmp/asus-firmware/* /usr/lib/firmware/
rm -rf /tmp/asus-firmware

QUALIFIED_KERNEL="$(rpm -qa | grep -P 'kernel-(\d+)' | grep 'rog' | sed -E 's/kernel-//')"
/usr/libexec/rpm-ostree/wrapped/dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible --zstd -v --add ostree -f "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"

chmod 0600 /lib/modules/$QUALIFIED_KERNEL/initramfs.img

dnf5 -y copr disable ublue-os/staging
dnf5 -y copr disable ublue-os/akmods
dnf5 -y copr disable rok/cdemu