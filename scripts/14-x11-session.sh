#!/bin/bash
# Kirana OS - 14: Login & desktop memakai X11 (bukan Wayland)
# Alasan: di VirtualBox (driver vmwgfx) perpindahan layar login -> desktop di Wayland
# kadang membeku pada gambar terakhir layar login. X11 lebih stabil di VM dan widget
# conky berjalan langsung tanpa lapisan Xwayland.
set -e
F=/etc/gdm3/custom.conf
if grep -q '^WaylandEnable=' $F; then
  sudo sed -i 's/^WaylandEnable=.*/WaylandEnable=false/' $F
else
  sudo sed -i '/^\[daemon\]/a WaylandEnable=false' $F
fi
grep -n 'WaylandEnable' $F
echo "Aktif setelah reboot. Kembalikan ke Wayland: hapus baris WaylandEnable=false di $F"
