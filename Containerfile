## 1. BUILD ARGS
# These allow changing the produced image by passing different build args to adjust
# the source from which your image is built.
# Build args can be provided on the commandline when building locally with:
#   podman build -f Containerfile --build-arg FEDORA_VERSION=40 -t local-image

# SOURCE_IMAGE arg can be anything from ublue upstream which matches your desired version:
# See list here: https://github.com/orgs/ublue-os/packages?repo_name=main
# - "silverblue"
# - "kinoite"
# - "sericea"
# - "onyx"
# - "lazurite"
# - "vauxite"
# - "base"
#
#  "aurora", "bazzite", "bluefin" or "ucore" may also be used but have different suffixes.
ARG SOURCE_IMAGE="bluefin"

## SOURCE_SUFFIX arg should include a hyphen and the appropriate suffix name
# These examples all work for silverblue/kinoite/sericea/onyx/lazurite/vauxite/base
# - "-main"
# - "-nvidia"
# - "-asus"
# - "-asus-nvidia"
# - "-surface"
# - "-surface-nvidia"
#
# aurora, bazzite and bluefin each have unique suffixes. Please check the specific image.
# ucore has the following possible suffixes
# - stable
# - stable-nvidia
# - stable-zfs
# - stable-nvidia-zfs
# - (and the above with testing rather than stable)
ARG SOURCE_SUFFIX="-main"

## SOURCE_TAG arg must be a version built for the specific image: eg, 39, 40, gts, latest
ARG SOURCE_TAG="latest"


### 2. SOURCE IMAGE
## this is a standard Containerfile FROM using the build ARGs above to select the right upstream image
FROM ghcr.io/ublue-os/${SOURCE_IMAGE}${SOURCE_SUFFIX}:${SOURCE_TAG}
# FROM quay.io/fedora-ostree-desktops/silverblue:41

ARG SOURCE_IMAGE="bluefin"
ARG SOURCE_SUFFIX="-main"
ARG SOURCE_TAG="latest"
ENV SUFFIX="${SOURCE_SUFFIX}"
ENV IMAGE="${SOURCE_IMAGE}${SOURCE_SUFFIX}"
ENV SOURCE_TAG="${SOURCE_TAG}"


### 3. INSTALL SURFACE KERNEL AND DRIVERS
# Use prebuilt Surface kernel from ublue akmods
COPY --from=ghcr.io/ublue-os/akmods:main-42 /tmp/rpms/kmods/kernel-modules-extra-6.*.fc42.x86_64.rpm /tmp/surface-kmods/
COPY --from=ghcr.io/ublue-os/akmods:main-42 /tmp/rpms/kmods/*surface*.rpm /tmp/surface-kmods/

RUN mkdir -p /var/lib/alternatives && \
    # Install Surface Linux repository
    curl -s https://pkg.surfacelinux.com/fedora/linux-surface.repo > /etc/yum.repos.d/linux-surface.repo && \
    # Install Surface kernel and modules
    rpm-ostree override replace \
        --experimental \
        /tmp/surface-kmods/kernel-modules-extra-*.rpm && \
    rpm-ostree install \
        --allow-inactive \
        /tmp/surface-kmods/*surface*.rpm \
        iptsd \
        libwacom-surface \
        surface-hardware-setup && \
    # Cleanup
    rm -rf /tmp/surface-kmods && \
    ostree container commit

## NOTES:
# - /var/lib/alternatives is required to prevent failure with some RPM installs
# - All RUN commands must end with ostree container commit
#   see: https://coreos.github.io/rpm-ostree/container/#using-ostree-container-commit

# FROM quay.io/fedora-ostree-desktops/silverblue:41

# RUN dnf5 config-manager addrepo --from-repofile=https://pkg.surfacelinux.com/fedora/linux-surface.repo 
# RUN dnf5 -y remove kernel* && \
#     rm -r /root # not necessary on ublue-os/main derived images
#     ostree container commit


### 4. SURFACE CUSTOMIZATIONS
COPY build.sh /tmp/build.sh
RUN chmod +x /tmp/build.sh && \
    /tmp/build.sh && \
    ostree container commit

