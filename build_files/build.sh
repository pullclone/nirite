#!/bin/bash

set -ouex pipefail

# -------------------------------
# 1. Define user
# -------------------------------
USER="yourusername"
USER_HOME="/home/$USER"

# -------------------------------
# 2. Remove KDE if present
# -------------------------------
dnf5 -y remove plasma-workspace plasma-* kde-* || true

# -------------------------------
# 3. Install packages
# -------------------------------
dnf5 -y copr enable zhangyi6324/noctalia-shell
dnf5 -y install \
    niri \
    kitty \
    gdm \
    brightnessctl \
    cava \
    wlsunset \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal-gnome \
    python3 \
    evolution-data-server \
    gnome-keyring \
    nautilus \
    emacs \
    micro \
    fuzzel \
    polkit-kde \
    xwayland-satellite

# -------------------------------
# 4. Enable system services
# -------------------------------
systemctl enable podman.socket
