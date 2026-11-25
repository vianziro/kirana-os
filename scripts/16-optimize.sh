#!/bin/bash
# Kirana OS - 16: Optimasi lanjutan (lebih ringan, boot lebih cepat, disk lebih hemat)
set -e

echo "[1/5] Bersihkan sisa snap yang restart tiap 2 detik (spam log + CPU)"
sudo rm -f /etc/xdg/systemd/user/snap.snapd-desktop-integration.snapd-desktop-integration.service \
           /etc/xdg/autostart/snap-userd-autostart.desktop
systemctl --user daemon-reload 2>/dev/null || true
systemctl --user reset-failed 2>/dev/null || true

echo "[2/5] Matikan layanan yang tidak dipakai di VM lab"
# gnome-remote-desktop : RDP bawaan GNOME (akses jarak jauh sudah lewat SSH)
# switcheroo-control   : pengalih GPU ganda (laptop hybrid), tidak ada di VM
# rsyslog              : log teks ganda; journald sudah mencatat semuanya
# NetworkManager-wait-online : menahan boot sampai jaringan siap
# packagekit           : backend GNOME Software (tidak terpasang)
for s in gnome-remote-desktop switcheroo-control rsyslog NetworkManager-wait-online packagekit; do
  sudo systemctl disable --now $s.service 2>/dev/null || true
done
sudo systemctl mask packagekit.service >/dev/null 2>&1 || true

echo "[3/5] Batasi ukuran log (journald maks 100 MB)"
sudo mkdir -p /etc/systemd/journald.conf.d
printf '[Journal]\nSystemMaxUse=100M\nRuntimeMaxUse=30M\n' | sudo tee /etc/systemd/journald.conf.d/kirana.conf >/dev/null
sudo systemctl restart systemd-journald
sudo journalctl --vacuum-size=100M >/dev/null 2>&1

echo "[4/5] TRIM mingguan (disk virtual mengecil di Mac saat file dihapus)"
sudo systemctl enable --now fstrim.timer >/dev/null 2>&1

echo "[5/5] Bersihkan cache apt"
sudo apt-get -qq autoremove --purge -y >/dev/null 2>&1 || true
sudo apt-get -qq clean
echo "Optimasi selesai. Log: $(journalctl --disk-usage | grep -oE '[0-9.]+[MG]')"
