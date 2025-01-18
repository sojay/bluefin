#!/bin/bash
set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

# dnf5 -y copr enable ublue-os/staging
# dnf5 -y copr enable ublue-os/akmods

# skopeo copy docker://ghcr.io/ublue-os/akmods-extra:surface-"${RELEASE}" dir:/tmp/akmods-extra-rpms
# AKMODS_EXTRA_TARGZ=$(jq -r '.layers[].digest' < /tmp/akmods-extra-rpms/manifest.json | cut -d : -f 2)
# tar -xvzf /tmp/akmods-extra-rpms/"$AKMODS_EXTRA_TARGZ" -C /tmp/
# mv /tmp/rpms/* /tmp/akmods-extra-rpms/


# if [[ $SUFFIX == *"nvidia"* ]]; then
#   skopeo copy docker://ghcr.io/ublue-os/akmods-nvidia-open:surface-"${RELEASE}" dir:/tmp/akmods-nvidia-open-rpms
#   AKMODS_NVIDIA_OPEN_TARGZ=$(jq -r '.layers[].digest' < /tmp/akmods-nvidia-open-rpms/manifest.json | cut -d : -f 2)
#   tar -xvzf /tmp/akmods-nvidia-open-rpms/"$AKMODS_NVIDIA_OPEN_TARGZ" -C /tmp/
#   mv /tmp/rpms/* /tmp/akmods-nvidia-open-rpms/

#   rpm --erase kmod-nvidia --nodeps ; 
# fi

# Install Surface-specific packages
dnf5 -y install --allowerasing \
  iptsd \
  libwacom-surface

# dnf5 -y copr enable ublue-os/staging
# dnf5 -y copr enable ublue-os/akmods

# Install additional packages
rpm-ostree install screen

#### Example for enabling a System Unit File
# systemctl enable podman.socket

# Cleanup
# dnf5 -y copr disable ublue-os/staging
# dnf5 -y copr disable ublue-os/akmods