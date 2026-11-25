#!/bin/bash
# Kirana OS - 08: Lebih kencang & ringan
#   - zram: swap terkompresi di RAM (zstd), tidak menyentuh disk
#   - buang snap seluruhnya (snapd + 9 snap), Firefox diganti .deb resmi Mozilla
#   - profil Firefox lama (bookmark, history) dipindahkan
set -e
export DEBIAN_FRONTEND=noninteractive
APT="sudo apt-get -o DPkg::Lock::Timeout=600 -y -qq"

echo "[1/4] zram (swap terkompresi 50% RAM)"
$APT install zram-tools >/dev/null
printf 'ALGO=zstd\nPERCENT=50\nPRIORITY=100\n' | sudo tee /etc/default/zramswap >/dev/null
sudo systemctl restart zramswap
printf 'vm.swappiness=100\nvm.vfs_cache_pressure=50\nvm.page-cluster=0\n' | sudo tee /etc/sysctl.d/99-kirana.conf >/dev/null
sudo sysctl -q --system
# swappiness tinggi itu benar untuk zram: lebih murah kompres RAM daripada membuang cache

echo "[2/4] Pindahkan profil Firefox dari snap"
if pgrep -x firefox >/dev/null; then echo "  Tutup Firefox dulu lalu jalankan ulang skrip ini."; exit 1; fi
if [ -d ~/snap/firefox/common/.mozilla/firefox ] && [ ! -d ~/.mozilla/firefox ]; then
  mkdir -p ~/.mozilla && cp -a ~/snap/firefox/common/.mozilla/firefox ~/.mozilla/
fi

echo "[3/4] Hapus semua snap + snapd"
if command -v snap >/dev/null; then
  for s in firefox snap-store snapd-desktop-integration firmware-updater gnome-42-2204 gnome-46-2404 \
           gtk-common-themes mesa-2404 core22 core24 bare; do
    sudo snap remove --purge "$s" >/dev/null 2>&1 || true
  done
  sudo snap remove --purge snapd >/dev/null 2>&1 || true
fi
$APT purge snapd >/dev/null
sudo rm -rf ~/snap /snap /var/snap /var/lib/snapd /var/cache/snapd
# cegah snapd terpasang lagi lewat paket "firefox" versi Ubuntu (transisi ke snap)
sudo tee /etc/apt/preferences.d/kirana-nosnap >/dev/null <<'EOF'
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF

echo "[4/4] Firefox .deb dari repositori resmi Mozilla"
sudo install -d -m 0755 /etc/apt/keyrings
wget -qO- https://packages.mozilla.org/apt/repo-signing-key.gpg | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc >/dev/null
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | \
  sudo tee /etc/apt/sources.list.d/mozilla.list >/dev/null
sudo tee /etc/apt/preferences.d/mozilla >/dev/null <<'EOF'
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF
sudo apt-get -qq update
$APT install firefox >/dev/null
# dock: ikon Firefox snap -> .deb
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus
gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed 's/firefox_firefox.desktop/firefox.desktop/')"
echo "Selesai. Swap: $(swapon --show=NAME,SIZE --noheadings | tr '\n' ' ')"
