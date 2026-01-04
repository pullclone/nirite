#!/bin/bash

set -ouex pipefail

# -------------------------------
# 1. Remove KDE if present
# -------------------------------
dnf5 -y remove plasma-workspace plasma-* kde-* || true

# -------------------------------
# 2. Get Terra Mesa key
# -------------------------------
# Terra mesa key (only needed if terra-mesa repo is enabled)
install -d /etc/pki/rpm-gpg
curl -fsSL https://repos.fyralabs.com/terra43-mesa/key.asc \
  -o /etc/pki/rpm-gpg/RPM-GPG-KEY-terra43-mesa

dnf5 -y install terra-release

# Disable Terra Mesa repo (ISO depsolve shouldn't depend on it)
if [ -f /etc/yum.repos.d/terra-mesa.repo ]; then
  sed -i 's/^enabled=1/enabled=0/' /etc/yum.repos.d/terra-mesa.repo
fi

# -------------------------------
# 2. Install packages
# -------------------------------
dnf5 -y copr enable zhangyi6324/noctalia-shell
dnf5 -y copr enable varlad/macchina
dnf5 -y copr enable clarlok/lost
dnf5 -y install \
    niri \
    kitty \
    gdm \
    brightnessctl \
    cava \
    wlsunset \
    astroterm \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal-gnome \
    shim-x64 \
    grub2-efi-x64 \
    python3 \
    uv \
    evolution-data-server \
    gnome-keyring \
    noctalia-shell \
    docker-buildkit \
    docker-distribution \
    eza \
    inxi \
    rustup \
    iproute \
    mtr \
    trash-cli \
    nautilus \
    ollama \
    emacs \
    micro \
    typespeed \
    tmux \
    navi \
    glow \
    age \
    btop \
    starship \
    zoxide \
    fuzzel \
    polkit-kde \
    xwayland-satellite

# -------------------------------
# 3. Enable system services
# -------------------------------
systemctl enable podman.socket

# -------------------------------
# 4. Cleanup
# -------------------------------
dnf5 clean all
rm -rf /var/lib/dnf
