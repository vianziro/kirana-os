#!/bin/bash
# Kirana OS - 09: Wallpaper dinamis (berganti mengikuti jam, fitur bawaan GNOME)
#   05:00 pagi -> 10:00 siang -> 16:00 senja -> 18:00 malam, transisi halus 30 menit
#   Tanpa daemon tambahan: GNOME membaca jadwal dari file XML.
set -e
HERE="$(cd "$(dirname "$0")/.." && pwd)"
D=/usr/share/backgrounds/kirana
TMP=$(mktemp -d)
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus

echo "[1/3] Render 4 varian"
python3 "$HERE/assets/wallpaper/make_variants.py" "$HERE/assets/wallpaper.svg" "$TMP" >/dev/null
for v in pagi siang senja malam; do
  rsvg-convert -w 2560 -h 1440 "$TMP/$v.svg" | sudo tee $D/$v.png >/dev/null
done

echo "[2/3] Jadwal XML"
st() { echo "<static><duration>$1</duration><file>$D/$2.png</file></static>"; }
trn() { echo "<transition type=\"overlay\"><duration>1800</duration><from>$D/$1.png</from><to>$D/$2.png</to></transition>"; }
sudo tee $D/kirana-dinamis.xml >/dev/null <<EOF
<background>
  <starttime><year>2026</year><month>1</month><day>1</day><hour>5</hour><minute>0</minute><second>0</second></starttime>
  $(st 16200 pagi)  $(trn pagi siang)
  $(st 19800 siang) $(trn siang senja)
  $(st 5400 senja)  $(trn senja malam)
  $(st 37800 malam) $(trn malam pagi)
</background>
EOF
# daftarkan agar muncul di Settings > Appearance
sudo tee /usr/share/gnome-background-properties/kirana.xml >/dev/null <<EOF
<?xml version="1.0"?>
<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
<wallpapers>
  <wallpaper deleted="false"><name>Kirana Dinamis</name><filename>$D/kirana-dinamis.xml</filename><options>zoom</options></wallpaper>
  <wallpaper deleted="false"><name>Kirana Pagi</name><filename>$D/pagi.png</filename><options>zoom</options></wallpaper>
  <wallpaper deleted="false"><name>Kirana Siang</name><filename>$D/siang.png</filename><options>zoom</options></wallpaper>
  <wallpaper deleted="false"><name>Kirana Senja</name><filename>$D/senja.png</filename><options>zoom</options></wallpaper>
  <wallpaper deleted="false"><name>Kirana Malam</name><filename>$D/malam.png</filename><options>zoom</options></wallpaper>
</wallpapers>
EOF

echo "[3/3] Pakai sebagai wallpaper"
for k in picture-uri picture-uri-dark; do
  gsettings set org.gnome.desktop.background $k "file://$D/kirana-dinamis.xml"
done
rm -rf "$TMP"
echo "Wallpaper dinamis aktif (sekarang: $(date +%H:%M))."
