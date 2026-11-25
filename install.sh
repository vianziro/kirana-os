#!/bin/bash
# Kirana OS 1.0 "Senja" - remaster Ubuntu 24.04 GNOME
# Jalankan dari sesi desktop user (bukan root):  bash install.sh
set -e
cd "$(dirname "$0")"
for s in scripts/[0-9]*.sh; do
  echo; echo "==================== $s ===================="
  bash "$s"
done
echo; echo "Selesai. Reboot untuk melihat GRUB, splash, dan layar login baru:  sudo reboot"
