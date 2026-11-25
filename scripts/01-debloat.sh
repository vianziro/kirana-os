#!/bin/bash
# Kirana OS - 01: Debloat tingkat "sedang"
# Jalankan sebagai user biasa (pakai sudo). Aman diulang.
set -e
export DEBIAN_FRONTEND=noninteractive
APT="sudo apt-get -o DPkg::Lock::Timeout=600 -y -qq"

echo "[1/4] Matikan layanan yang tidak perlu di VM lab"
for s in unattended-upgrades cups cups-browsed ModemManager kerneloops \
         whoopsie apport avahi-daemon; do
  sudo systemctl disable --now "$s" 2>/dev/null || true
done
sudo systemctl disable --now apt-daily.timer apt-daily-upgrade.timer motd-news.timer 2>/dev/null || true

echo "[2/4] Hapus paket yang jarang dipakai"
$APT purge snap-store 2>/dev/null || sudo snap remove snap-store 2>/dev/null || true
$APT purge update-notifier apport whoopsie kerneloops ubuntu-report popularity-contest 2>/dev/null || true
$APT autoremove --purge

echo "[3/4] Matikan indexer file (tracker) dan pengingat kalender"
mkdir -p ~/.config/autostart
for f in /etc/xdg/autostart/org.gnome.Evolution-alarm-notify.desktop \
         /etc/xdg/autostart/tracker-miner-fs-3.desktop \
         /etc/xdg/autostart/update-notifier.desktop; do
  [ -f "$f" ] && { cp "$f" ~/.config/autostart/; echo "Hidden=true" >> ~/.config/autostart/$(basename "$f"); }
done
systemctl --user mask tracker-miner-fs-3.service tracker-extract-3.service 2>/dev/null || true

echo "[4/4] Matikan animasi GNOME dan kurangi swap"
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus
gsettings set org.gnome.desktop.interface enable-animations false
gsettings set org.gnome.desktop.search-providers disable-external true
echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-kirana.conf >/dev/null
sudo sysctl -q -p /etc/sysctl.d/99-kirana.conf
echo "Debloat selesai."
