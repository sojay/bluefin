# image-template

# Purpose

This repository is meant to be a template for building your own custom Universal Blue image. This template is the recommended way to make customizations to any image published by the Universal Blue Project:
- [Aurora](https://getaurora.dev/)
- [Bazzite](https://bazzite.gg/)
- [Bluefin](https://projectbluefin.io/)
- [uCore](https://projectucore.io/)
- [main](https://github.com/ublue-os/main/)
- [hwe](https://github.com/ublue-os/hwe/) 

This template includes a Containerfile and a Github workflow for building the container image. As soon as the workflow is enabled in your repository, it will build the container image and push it to the Github Container Registry.

# Prerequisites

Working knowledge in the following topics:

- Containers
  - https://www.youtube.com/watch?v=SnSH8Ht3MIc
  - https://www.mankier.com/5/Containerfile
- rpm-ostree
  - https://coreos.github.io/rpm-ostree/container/
- Fedora Silverblue (and other Fedora Atomic variants)
  - https://docs.fedoraproject.org/en-US/fedora-silverblue/
- Github Workflows
  - https://docs.github.com/en/actions/using-workflows

# How to Use

## Template

Select `Use this Template` and create a new repository from it. To enable the workflows, you may need to go the `Actions` tab of the new repository and click to enable workflows.

## Containerfile

This file defines the operations used to customize the selected image. It contains examples of possible modifications, including how to:
- change the upstream from which the custom image is derived
- add additional RPM packages
- add binaries as a layer from other images

## Workflows

### build.yml

This workflow creates your custom OCI image and publishes it to the Github Container Registry (GHCR). By default, the image name will match the Github repository name.

#### Container Signing

Container signing is important for end-user security and is enabled on all Universal Blue images. It is recommended you set this up, and by default the image builds *will fail* if you don't.

This provides users a method of verifying the image.

1. Install the [cosign CLI tool](https://edu.chainguard.dev/open-source/sigstore/cosign/how-to-install-cosign/#installing-cosign-with-the-cosign-binary)

2. Run inside your repo folder:

    ```bash
    cosign generate-key-pair
    ```

    
    - Do NOT put in a password when it asks you to, just press enter. The signing key will be used in GitHub Actions and will not work if it is encrypted.

> [!WARNING]
> Be careful to *never* accidentally commit `cosign.key` into your git repo.

3. Add the private key to GitHub

    - This can also be done manually. Go to your repository settings, under Secrets and Variables -> Actions
    ![image](https://user-images.githubusercontent.com/1264109/216735595-0ecf1b66-b9ee-439e-87d7-c8cc43c2110a.png)
    Add a new secret and name it `SIGNING_SECRET`, then paste the contents of `cosign.key` into the secret and save it. Make sure it's the .key file and not the .pub file. Once done, it should look like this:
    ![image](https://user-images.githubusercontent.com/1264109/216735690-2d19271f-cee2-45ac-a039-23e6a4c16b34.png)

    - (CLI instructions) If you have the `github-cli` installed, run:

    ```bash
    gh secret set SIGNING_SECRET < cosign.key
    ```

4. Commit the `cosign.pub` file to the root of your git repository.

### Examples
- [m2os](https://github.com/m2giles/m2os)
- [bos](https://github.com/bsherman/bos)
- [homer](https://github.com/bketelsen/homer/)

# Bluefin Surface Book 2 Custom Image

A custom Universal Blue image for Surface Book 2 based on Bluefin DX Surface edition.

## Current Status

Based on upstream issues with Surface support:
- Using `bluefin-dx-surface:latest` which includes Bazzite kernel
- Minimal build approach to avoid boot conflicts
- Known kernel issues: 6.10.10+ doesn't boot, 6.9.x works

## What this adds

- Surface-specific sleep/suspend configurations  
- IPTS touchscreen permissions
- Additional Surface control utilities

## Building

```bash
podman build -t bluefin-surface .
```

## Deployment

### Verify Kernel Version First

```bash
podman run --rm ghcr.io/sojay/bluefin:latest rpm -qa | grep kernel
```
- ✅ Good: `kernel-6.9.x` or contains `bazzite`
- ❌ Bad: `kernel-6.10.10+` (known boot issues)

### Deploy

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/sojay/bluefin:latest
sudo systemctl reboot
```

### Update Existing

```bash
sudo rpm-ostree upgrade
```

## Troubleshooting Boot Issues

### Black Screen
- **Cause**: Incompatible kernel
- **Fix**: Hold Shift at boot → select pinned backup
- **Rollback**: `sudo rpm-ostree rollback`

### Deployment Mismatch
- **Error**: "Could not resolve init executable"
- **Fix**: Boot GRUB (hold Shift) → select working deployment
- **Cleanup**: `sudo rpm-ostree cleanup -r`

### Keep Backup
```bash
sudo ostree admin pin 0
```

## Approach

**Minimal Build Strategy** - Based on upstream Surface support issues:
- Uses `bluefin-dx-surface:latest` (includes Bazzite kernel for Surface)
- No modifications to base image (ensures stability)
- Relies on upstream Surface support from Universal Blue

## References

- [Bluefin Surface/Asus Issues](https://github.com/ublue-os/bluefin/issues/2051)
- [Fedora 40 kernel 6.10 boot issues](https://github.com/linux-surface/linux-surface/issues/1560)
- [Surface Pro 10 support status](https://github.com/linux-surface/linux-surface/issues/1608)
