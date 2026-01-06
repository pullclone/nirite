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
    bluez \
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
    gnupg2 \
    gnupg2-keyboxd \
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
# 2.1 Ensure manpages for unit docs
# -------------------------------
if [ ! -f /usr/share/man/man1/mpris-proxy.1 ] && [ ! -f /usr/share/man/man1/mpris-proxy.1.gz ]; then
  install -d /usr/share/man/man1
  cat > /usr/share/man/man1/mpris-proxy.1 <<'EOF'
.TH MPRIS-PROXY 1 "Local" "nirite" "User Commands"
.SH NAME
mpris-proxy \- Bluetooth MPRIS proxy helper
.SH DESCRIPTION
Stub manual page installed by the image build to satisfy systemd unit documentation checks.
EOF
fi

if [ ! -f /usr/share/man/man8/keyboxd.8 ] && [ ! -f /usr/share/man/man8/keyboxd.8.gz ]; then
  install -d /usr/share/man/man8
  cat > /usr/share/man/man8/keyboxd.8 <<'EOF'
.TH KEYBOXD 8 "Local" "nirite" "System Administration"
.SH NAME
keyboxd \- GnuPG keybox daemon
.SH DESCRIPTION
Stub manual page installed by the image build to satisfy systemd unit documentation checks.
EOF
fi

# Ensure keyboxd path matches unit expectations
if [ ! -e /usr/lib/gnupg/keyboxd ]; then
  if [ -x /usr/libexec/keyboxd ]; then
    install -d /usr/lib/gnupg
    ln -s /usr/libexec/keyboxd /usr/lib/gnupg/keyboxd
  elif [ -x /usr/libexec/gnupg/keyboxd ]; then
    install -d /usr/lib/gnupg
    ln -s /usr/libexec/gnupg/keyboxd /usr/lib/gnupg/keyboxd
  fi
fi
if [ -e /usr/lib/gnupg/keyboxd ] && [ ! -x /usr/lib/gnupg/keyboxd ]; then
  chmod +x /usr/lib/gnupg/keyboxd
fi

# -------------------------------
# 3. Enable system services
# -------------------------------
systemctl enable podman.socket

# -------------------------------
# 4. Cleanup
# -------------------------------
dnf5 clean all
rm -rf /var/lib/dnf
