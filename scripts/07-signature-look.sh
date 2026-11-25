#!/bin/bash
# Kirana OS - 07: Tampilan khas Kirana
#   - tema GNOME Shell "Kirana" (turunan Orchis): panel kaca mengambang, logo K, dock kaca
#   - widget desktop (conky): sapaan, jam besar, tanggal Indonesia, statistik, kredit
set -e
HERE="$(cd "$(dirname "$0")/.." && pwd)"
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus
APT="sudo apt-get -o DPkg::Lock::Timeout=600 -y -qq"

echo "[1/4] Tema shell 'Kirana' = Orchis-Teal-Dark + CSS Kirana"
sudo rm -rf /usr/share/themes/Kirana
sudo mkdir -p /usr/share/themes/Kirana
sudo cp -r /usr/share/themes/Orchis-Teal-Dark/gnome-shell /usr/share/themes/Kirana/
sudo cp "$HERE/assets/kirana-logo.svg" /usr/share/themes/Kirana/gnome-shell/
cat "$HERE/assets/shell/kirana-shell.css" | sudo tee -a /usr/share/themes/Kirana/gnome-shell/gnome-shell.css >/dev/null

sudo locale-gen id_ID.UTF-8 >/dev/null
echo "[2/4] Aktifkan ekstensi User Themes + pilih tema Kirana"
gsettings set org.gnome.shell enabled-extensions "['user-theme@gnome-shell-extensions.gcampax.github.com']"
gsettings set org.gnome.shell.extensions.user-theme name 'Kirana' 2>/dev/null || \
  dconf write /org/gnome/shell/extensions/user-theme/name "'Kirana'"
gsettings set org.gnome.desktop.interface enable-animations true   # animasi halus = terasa "premium"
sudo localectl set-locale LANG=en_US.UTF-8 LC_TIME=id_ID.UTF-8    # jam & tanggal berbahasa Indonesia, menu tetap Inggris
gsettings set org.gnome.system.locale region 'id_ID.UTF-8'

echo "[3/4] Widget desktop (conky) + locale Indonesia untuk tanggal"
$APT install conky-all >/dev/null 2>&1
sudo mkdir -p /etc/kirana
sudo cp "$HERE/assets/conky/kirana.conf" /etc/kirana/conky.conf
sudo tee /etc/kirana/greet.sh >/dev/null <<'EOF'
#!/bin/bash
h=$(date +%H); n=$(getent passwd "$USER" | cut -d: -f5 | cut -d, -f1); n=${n:-$USER}
if   [ $h -lt 11 ]; then s="Selamat pagi"
elif [ $h -lt 15 ]; then s="Selamat siang"
elif [ $h -lt 18 ]; then s="Selamat sore"
else s="Selamat malam"; fi
echo "$s, $n"
EOF
sudo chmod +x /etc/kirana/greet.sh
sudo tee /etc/xdg/autostart/kirana-widget.desktop >/dev/null <<'EOF'
[Desktop Entry]
Type=Application
Name=Kirana Widget
Exec=sh -c "sleep 4; conky -c /etc/kirana/conky.conf"
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

echo "[4/4] Jalankan widget sekarang"
pkill -x conky 2>/dev/null || true
export DISPLAY=:0 XAUTHORITY=$(ls /run/user/$(id -u)/.mutter-Xwaylandauth.* 2>/dev/null | head -1)
nohup conky -c /etc/kirana/conky.conf >/dev/null 2>&1 &
echo "Tampilan khas Kirana selesai."
