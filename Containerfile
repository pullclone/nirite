# Allow referencing build scripts without copying into image
FROM scratch AS ctx
COPY build_files /

# Bazzite image
FROM ghcr.io/ublue-os/bazzite-dx:stable

# Universal Blue images: https://github.com/orgs/ublue-os/packages

COPY services /usr/lib/systemd/user/

# Modifications to packages via build.sh script 
# FIX ADDED: We manually populate EFI directories between build.sh and the commit
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh && \
    # --- START FIX FOR BOOTC-IMAGE-BUILDER ---
    # Manually create the EFI vendor directories that bootc-image-builder expects
    mkdir -p /boot/efi/EFI/fedora /boot/efi/EFI/BOOT && \
    # Copy the shim binary to the vendor directory and as the default BOOTX64.EFI
    cp /usr/share/shim/*/shimx64.efi /boot/efi/EFI/fedora/ && \
    cp /usr/share/shim/*/shimx64.efi /boot/efi/EFI/BOOT/BOOTX64.EFI && \
    # Copy the grub binary if it exists
    if [ -f /usr/lib/grub/x86_64-efi/grub.efi ]; then \
      cp /usr/lib/grub/x86_64-efi/grub.efi /boot/efi/EFI/fedora/grubx64.efi; \
    fi && \
    # --- END FIX ---
    ostree container commit

# Final image linting
RUN bootc container lint
