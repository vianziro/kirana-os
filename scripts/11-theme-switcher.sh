#!/bin/bash
# Kirana OS - 11: Ganti tema satu perintah (terinspirasi Omarchy)
#   kirana-theme senja | nord | catppuccin | gruvbox | tokyo-night
set -e
HERE="$(cd "$(dirname "$0")/.." && pwd)"
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus

echo "[1/4] Varian Orchis untuk tiap tema"
if [ ! -d /usr/share/themes/Orchis-Dark-Nord ]; then
  T=$(mktemp -d); git clone -q --depth 1 https://github.com/vinceliuice/Orchis-theme "$T/o"
  O="-c dark -s standard -i simple --round 10px"
  for c in default purple orange; do sudo "$T/o/install.sh" -d /usr/share/themes -t $c $O --tweaks solid >/dev/null 2>&1; done
  sudo "$T/o/install.sh" -d /usr/share/themes -t default $O --tweaks solid nord >/dev/null 2>&1
  rm -rf "$T"
fi

echo "[2/4] Data tema + alat kirana-theme"
sudo mkdir -p /usr/share/kirana/themes
sudo cp "$HERE"/assets/themes/*.theme /usr/share/kirana/themes/
sudo cp "$HERE/assets/shell/kirana-shell.css" "$HERE/assets/kirana-logo.svg" "$HERE/assets/wallpaper.svg" /usr/share/kirana/
sudo install -m755 "$HERE/assets/bin/kirana-theme" /usr/local/bin/kirana-theme
sudo tee /usr/share/applications/kirana-theme.desktop >/dev/null <<'EOF'
[Desktop Entry]
Type=Application
Name=Kirana Theme
Comment=Ganti tema Kirana OS
Exec=kirana-theme
Icon=kirana-logo
Categories=Settings;
EOF

echo "[3/4] Terminal & widget membaca konfigurasi user (~/.config/kirana) bila ada"
for rc in ~/.bashrc /etc/skel/.bashrc; do
  S=""; [ -w "$rc" ] || S=sudo
  $S sed -i \
    -e 's|^export STARSHIP_CONFIG=/etc/kirana/starship.toml|K=~/.config/kirana; [ -f $K/starship.toml ] \|\| K=/etc/kirana\nexport STARSHIP_CONFIG=$K/starship.toml|' \
    -e 's|fastfetch -c /etc/kirana/fastfetch.jsonc|fastfetch -c $( [ -f ~/.config/kirana/fastfetch.jsonc ] \&\& echo ~/.config/kirana/fastfetch.jsonc \|\| echo /etc/kirana/fastfetch.jsonc )|g' "$rc"
done
sudo tee /usr/local/bin/kirana-widget >/dev/null <<'EOF'
#!/bin/sh
# jalankan widget desktop: pakai warna tema user bila ada
f="$HOME/.config/kirana/conky.conf"; [ -f "$f" ] || f=/etc/kirana/conky.conf
pkill -x conky 2>/dev/null; exec conky -c "$f"
EOF
sudo chmod 755 /usr/local/bin/kirana-widget
sudo sed -i 's|^Exec=.*|Exec=sh -c "sleep 4; exec kirana-widget"|' /etc/xdg/autostart/kirana-widget.desktop

echo "[4/4] Terapkan tema bawaan"
kirana-theme senja
