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
dnf5 -y install \
    niri \
    kitty \
    gdm \
    quickshell \
    brightnessctl \
    gpu-screen-recorder \
    cliphist \
    matugen-git \
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
    kcolorscheme \
    noctalia-shell \
    polkit-kde \
    xwayland-satellite

# -------------------------------
# 4. Enable system services
# -------------------------------
systemctl enable --now podman.socket
systemctl enable --global niri.service

# -------------------------------
# 5. Setup user-level Noctalia service
# -------------------------------

# Ensure linger is enabled so user services run even without login
loginctl enable-linger "$USER"

# Create systemd user directory
sudo -u "$USER" mkdir -p "$USER_HOME/.config/systemd/user"

# Copy service file (assumes build_files/noctalia.service exists)
sudo -u "$USER" cp build_files/noctalia.service "$USER_HOME/.config/systemd/user/noctalia.service"

# Reload user units
sudo -u "$USER" systemctl --user daemon-reload

# Enable and start noctalia
sudo -u "$USER" systemctl --user enable --now noctalia.service
