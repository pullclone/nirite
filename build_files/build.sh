#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# remove kde plasma
dnf5 -y remove plasma-workspace plasma-* kde-*

# setup niri
dnf5 -y install					\
	niri						\
	kitty						\
	gdm							\
	quickshell					\
	brightnessctl				\
	gpu-screen-recorder			\
	cliphist					\
	matugen-git					\
	cava						\
	wlsunset					\
	xdg-desktop-portal			\
	xdg-desktop-portal-gtk		\
	xdg-desktop-portal-gnome	\
	python3						\
	evolution-data-server		\
	gnome-keyring				\
	nautilus					\
	emacs						\
	micro						\
	fuzzel						\
	kcolorscheme				\
	noctalia-shell				\
	polkit-kde					\
	xwayland-satellite			\
	python3

systemctl enable podman.socketsystemctl
loginctl enable-linger $USERNAME
sudo -u $USERNAME systemctl --user daemon-reload
sudo -u $USERNAME systemctl --user enable --now noctalia.service
systemctl --global add-wants niri.service plasma-pokit-agent.service
