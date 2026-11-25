#!/bin/bash
# Kirana OS - 02: Tampilan desktop "dark minimal"
# Tema Orchis (teal, dark) + ikon Papirus-Dark + kursor Bibata + font Inter
set -e
export DEBIAN_FRONTEND=noninteractive
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus
APT="sudo apt-get -o DPkg::Lock::Timeout=600 -y -qq"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TMP=$(mktemp -d)

echo "[1/6] Paket pendukung"
$APT install git sassc gnome-shell-extensions gnome-tweaks \
  papirus-icon-theme fonts-inter fonts-jetbrains-mono wget >/dev/null

echo "[2/6] Tema GTK + GNOME Shell: Orchis Teal Dark"
git clone -q --depth 1 https://github.com/vinceliuice/Orchis-theme "$TMP/orchis"
OPTS="-t teal -c dark -s standard -i simple --round 10px --tweaks solid"
# sistem (dipakai juga oleh layar login)
sudo "$TMP/orchis/install.sh" -d /usr/share/themes $OPTS >/dev/null
# user + -l: link tema ke ~/.config/gtk-4.0 agar aplikasi libadwaita (Settings, Files) ikut gelap-teal
"$TMP/orchis/install.sh" $OPTS -l >/dev/null

echo "[3/6] Warna folder Papirus jadi teal"
wget -qO "$TMP/papirus-folders" https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/papirus-folders
sudo install -m755 "$TMP/papirus-folders" /usr/local/bin/papirus-folders
sudo papirus-folders -C teal --theme Papirus-Dark >/dev/null

echo "[4/6] Kursor Bibata"
wget -qO "$TMP/bibata.tar.xz" https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Ice.tar.xz
sudo tar -xf "$TMP/bibata.tar.xz" -C /usr/share/icons/

echo "[5/6] Wallpaper"
sudo mkdir -p /usr/share/backgrounds/kirana
sudo cp "$HERE/assets/wallpaper.svg" /usr/share/backgrounds/kirana/senja.svg
rsvg-convert -w 3840 -h 2160 "$HERE/assets/wallpaper.svg" | sudo tee /usr/share/backgrounds/kirana/senja.png >/dev/null

echo "[6/6] Terapkan pengaturan GNOME"
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null || true
gnome-extensions disable ding@rastersoft.com 2>/dev/null || true   # ikon di desktop -> bersih
I=org.gnome.desktop.interface
gsettings set $I color-scheme 'prefer-dark'
gsettings set $I gtk-theme 'Orchis-Teal-Dark'
gsettings set $I icon-theme 'Papirus-Dark'
gsettings set $I cursor-theme 'Bibata-Modern-Ice'
gsettings set $I font-name 'Inter 10.5'
gsettings set $I document-font-name 'Inter 10.5'
gsettings set $I monospace-font-name 'JetBrains Mono 11'
gsettings set $I clock-show-weekday true
gsettings set $I show-battery-percentage true
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Inter Semi-Bold 10.5'
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,close'
gsettings set org.gnome.shell.extensions.user-theme name 'Orchis-Teal-Dark' 2>/dev/null || \
  dconf write /org/gnome/shell/extensions/user-theme/name "'Orchis-Teal-Dark'"
for k in picture-uri picture-uri-dark; do
  gsettings set org.gnome.desktop.background $k 'file:///usr/share/backgrounds/kirana/senja.png'
done
gsettings set org.gnome.desktop.screensaver picture-uri 'file:///usr/share/backgrounds/kirana/senja.png'

# Dock: mengambang di bawah, ringkas, otomatis sembunyi
D=org.gnome.shell.extensions.dash-to-dock
gsettings set $D dock-position 'BOTTOM'
gsettings set $D extend-height false
gsettings set $D dock-fixed false
gsettings set $D autohide true
gsettings set $D intellihide true
gsettings set $D dash-max-icon-size 40
gsettings set $D show-trash false
gsettings set $D show-mounts false
gsettings set $D show-apps-at-top true
gsettings set $D transparency-mode 'FIXED'
gsettings set $D background-opacity 0.55
gsettings set $D custom-theme-shrink true
gsettings set $D running-indicator-style 'DOTS'
gsettings set org.gnome.shell favorite-apps "['firefox_firefox.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.Settings.desktop']"

rm -rf "$TMP"
echo "Tema desktop selesai."
