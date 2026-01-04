#!/bin/bash

set -ouex pipefail

# -------------------------------
# 1. Remove KDE if present
# -------------------------------
dnf5 -y remove plasma-workspace plasma-* kde-* || true

# -------------------------------
# 2. Get Terra Mesa key
# -------------------------------
install -d /etc/pki/rpm-gpg
curl -fsSL https://repos.fyralabs.com/terra43-mesa/key.asc \
  -o /etc/pki/rpm-gpg/RPM-GPG-KEY-terra43-mesa

# -------------------------------
# 2. Install packages
# -------------------------------
dnf5 -y copr enable zhangyi6324/noctalia-shell
dnf5 -y copr enable varlad/macchina
dnf5 -y copr enable clarlok/lost
dnf5 -y install \
    terra-release \
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
