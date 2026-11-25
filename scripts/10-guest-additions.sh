#!/bin/bash
# Kirana OS - 10: VirtualBox Guest Additions terbaru
#   -> clipboard Mac<->VM, drag & drop, layar ikut ukuran jendela, grafis lebih mulus
# Syarat: ISO Guest Additions dimasukkan (menu VM: Devices > Insert Guest Additions CD image)
set -e
export DEBIAN_FRONTEND=noninteractive
sudo apt-get -o DPkg::Lock::Timeout=600 -y -qq install build-essential bzip2 \
  "linux-headers-$(uname -r)" >/dev/null
M=$(mktemp -d)
sudo mount -o ro /dev/sr0 "$M"
RUN=$(ls "$M"/VBoxLinuxAdditions*.run | grep -E "$( [ "$(uname -m)" = aarch64 ] && echo arm64 || echo 'Additions.run')" | head -1)
echo "Installer: $RUN"
sudo sh "$RUN" --nox11 2>&1 | tail -6 || true
sudo umount "$M"; rmdir "$M"
sudo usermod -aG vboxsf "$USER" 2>/dev/null || true
echo "Guest Additions terpasang. Reboot agar aktif."
