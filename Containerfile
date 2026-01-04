# Allow referencing build scripts without copying into image
FROM scratch AS ctx
COPY build_files /

# Bazzite image
FROM ghcr.io/ublue-os/bazzite-dx:stable

# Universal Blue images: https://github.com/orgs/ublue-os/packages

COPY services /usr/lib/systemd/user/

# Modifications to packages via build.sh script 
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh && \
    set -euo pipefail; \
    \
    # --- START FIX FOR BOOTC-IMAGE-BUILDER ---
    # Prefer committed ostree boot payload location
    EFIROOT="/usr/lib/ostree-boot/efi"; \
    mkdir -p "${EFIROOT}/EFI/fedora" "${EFIROOT}/EFI/BOOT"; \
    \
    # Find shim (path varies across builds)
    SHIM="$(find /usr/share/shim /usr/lib/shim /usr/lib64/shim -type f -name 'shimx64.efi' 2>/dev/null | head -n1)"; \
    if [ -z "${SHIM}" ]; then \
      echo "WARN: shimx64.efi not found; skipping shim copy"; \
    else \
      cp -a "${SHIM}" "${EFIROOT}/EFI/fedora/"; \
      cp -a "${SHIM}" "${EFIROOT}/EFI/BOOT/BOOTX64.EFI"; \
    fi; \
    \
    # Copy grub EFI if present (path varies)
    if [ -f /usr/lib/grub/x86_64-efi/grub.efi ]; then \
      cp -a /usr/lib/grub/x86_64-efi/grub.efi "${EFIROOT}/EFI/fedora/grubx64.efi"; \
    elif [ -f /usr/lib/grub/x86_64-efi/grubx64.efi ]; then \
      cp -a /usr/lib/grub/x86_64-efi/grubx64.efi "${EFIROOT}/EFI/fedora/grubx64.efi"; \
    else \
      echo "WARN: grub EFI binary not found; continuing"; \
    fi; \
    \
    # Optional: mirror into /boot/efi too (harmless, but may not be what builder reads)
    mkdir -p /boot/efi/EFI/fedora /boot/efi/EFI/BOOT || true; \
    cp -a "${EFIROOT}/EFI/fedora/"* /boot/efi/EFI/fedora/ 2>/dev/null || true; \
    if [ -f "${EFIROOT}/EFI/BOOT/BOOTX64.EFI" ]; then \
      cp -a "${EFIROOT}/EFI/BOOT/BOOTX64.EFI" /boot/efi/EFI/BOOT/BOOTX64.EFI 2>/dev/null || true; \
    fi; \
    \
    ostree container commit

# Final image linting
RUN bootc container lint
