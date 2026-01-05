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
    # Prefer committed ostree boot payload location (fall back if /usr is read-only)
    EFIROOT="/usr/lib/ostree-boot/efi"; \
    if ! mkdir -p "${EFIROOT}/EFI/fedora" "${EFIROOT}/EFI/BOOT" 2>/dev/null; then \
      echo "WARN: ${EFIROOT} not writable; using /boot/efi"; \
      EFIROOT="/boot/efi"; \
      mkdir -p "${EFIROOT}/EFI/fedora" "${EFIROOT}/EFI/BOOT"; \
    fi; \
    \
    # Find shim (path varies across builds)
    SHIM="$(find /usr/share/shim /usr/lib/shim /usr/lib64/shim -type f -name 'shimx64.efi' -print -quit 2>/dev/null || true)"; \
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
    # Mirror into /boot/efi too for builder compatibility
    mkdir -p /boot/efi/EFI/fedora /boot/efi/EFI/BOOT || true; \
    cp -a "${EFIROOT}/EFI/fedora/"* /boot/efi/EFI/fedora/ 2>/dev/null || true; \
    if [ -f "${EFIROOT}/EFI/BOOT/BOOTX64.EFI" ]; then \
      cp -a "${EFIROOT}/EFI/BOOT/BOOTX64.EFI" /boot/efi/EFI/BOOT/BOOTX64.EFI 2>/dev/null || true; \
    fi; \
    \
    # Fix for bootc-image-builder: Populate EFI vendor directory so the builder detects 'fedora'
    mkdir -p /boot/efi/EFI/fedora || true; \
    cp /usr/share/shim/*/shimx64.efi /boot/efi/EFI/fedora/ 2>/dev/null || true; \
    cp /usr/lib/grub/x86_64-efi/grub.efi /boot/efi/EFI/fedora/grubx64.efi 2>/dev/null || true; \
    \
    # Ensure the ostree commit EFI root is populated when writable
    if [ -d /usr/lib/ostree-boot/efi/EFI ]; then \
      mkdir -p /usr/lib/ostree-boot/efi/EFI/fedora /usr/lib/ostree-boot/efi/EFI/BOOT || true; \
      cp -a /boot/efi/EFI/fedora/* /usr/lib/ostree-boot/efi/EFI/fedora/ 2>/dev/null || true; \
      if [ -f /boot/efi/EFI/BOOT/BOOTX64.EFI ]; then \
        cp -a /boot/efi/EFI/BOOT/BOOTX64.EFI /usr/lib/ostree-boot/efi/EFI/BOOT/BOOTX64.EFI 2>/dev/null || true; \
      fi; \
    fi

RUN set -euo pipefail; \
    ostree container commit

# Final image linting
RUN bootc container lint
