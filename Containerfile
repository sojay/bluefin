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
## NOTE: Previous bluefin-dx-surface:latest (Dec 2024, version 41.20241223.1) worked
## but is no longer available in registry. Using prebuilt kernel method instead.

ARG SOURCE_IMAGE="bluefin"
ARG SOURCE_SUFFIX="-dx"
ARG SOURCE_TAG="latest"

### 2. SOURCE IMAGE
FROM ghcr.io/ublue-os/${SOURCE_IMAGE}${SOURCE_SUFFIX}:${SOURCE_TAG}
# FROM quay.io/fedora-ostree-desktops/silverblue:41

ENV SUFFIX="${SOURCE_SUFFIX}"
ENV IMAGE="${SOURCE_IMAGE}${SOURCE_SUFFIX}"
ENV SOURCE_TAG="${SOURCE_TAG}"


### 3. MODIFICATIONS
## Use daegalus/redfin method: Pull prebuilt Surface kernel from ublue cache
COPY build-surface.sh /tmp/build-surface.sh
RUN chmod +x /tmp/build-surface.sh && \
    mkdir -p /var/lib/alternatives && \
    /tmp/build-surface.sh && \
    ostree container commit

