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
    mkdir -p /boot/efi/EFI/fedora && \
    ostree container commit

# Final image linting
RUN bootc container lint
