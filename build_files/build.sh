#!/bin/bash

set -ouex pipefail

# -------------------------------
# 1. Define user
# -------------------------------
USER="dmail"
USER_HOME="/home/$USER"

# -------------------------------
# 2. Remove KDE if present
# -------------------------------
dnf5 -y remove plasma-workspace plasma-* kde-* || true

# -------------------------------
# 3. Install packages
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
    python3 \
    uv \
    evolution-data-server \
    gnome-keyring \
    noctalia-shell \
    docker-compose \
    docker-cli \
    docker-buildkit \
    docker-buildx \
    docker-distribution \
    docker-compose-switch \
    eza \
    inxi \
    rustup \
    rustscan \
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
# 4. Enable system services
# -------------------------------
systemctl enable podman.socket
