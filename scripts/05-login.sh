#!/bin/bash
# Kirana OS - 05: Layar login (GDM): latar wallpaper buram, logo, ikon/kursor/font senada
set -e
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TMP=$(mktemp -d)
B=/usr/share/backgrounds/kirana

echo "[1/3] Latar login: wallpaper diburamkan + digelapkan"
sudo DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=600 -y -qq install libglib2.0-dev-bin >/dev/null
IMG="data:image/png;base64,$(base64 -w0 $B/senja.png)"
cat > "$TMP/login.svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1920" height="1080">
<defs><filter id="b" x="-200" y="-200" width="2320" height="1480" filterUnits="userSpaceOnUse"><feGaussianBlur stdDeviation="28"/></filter></defs>
<rect width="1920" height="1080" fill="#0E1230"/><image x="-160" y="-160" width="2240" height="1400" xlink:href="$IMG" preserveAspectRatio="xMidYMid slice" filter="url(#b)"/>
<rect width="1920" height="1080" fill="#0E1230" fill-opacity="0.45"/>
</svg>
EOF
rsvg-convert "$TMP/login.svg" -o "$TMP/login.png"
sudo cp "$TMP/login.png" $B/senja-login.png
LOGO_TXT=$(base64 -w0 "$HERE/assets/kirana-logo-text-dark.svg")
cat > "$TMP/logo-login.svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="320" height="104">
<image x="0" y="0" width="320" height="80" xlink:href="data:image/svg+xml;base64,$LOGO_TXT"/>
<text x="160" y="98" text-anchor="middle" font-family="Inter" font-size="12" font-weight="500" fill="#8C88B5" letter-spacing="3">BUILT BY <tspan fill="#FF9A5A">VIANZIRO</tspan></text>
</svg>
EOF
rsvg-convert -h 72 "$TMP/logo-login.svg" | sudo tee $B/logo-login.png >/dev/null

echo "[2/3] Tema GDM: salin gresource Yaru lalu tambahkan CSS Kirana"
SRC=/usr/share/gnome-shell/theme/Yaru/gnome-shell-theme.gresource
W="$TMP/gdm"; mkdir -p "$W"
for r in $(gresource list $SRC); do
  mkdir -p "$W/$(dirname ${r#/org/gnome/shell/theme/})"
  gresource extract $SRC $r > "$W/${r#/org/gnome/shell/theme/}"
done
CSS=$(cat <<EOF

/* ===== Kirana OS ===== */
#lockDialogGroup {
  background: #0E1230 url(file://$B/senja-login.png);
  background-size: cover; background-position: center; }
.login-dialog-prompt-entry, .unlock-dialog .login-dialog-prompt-entry { border-radius: 12px; }
.login-dialog .button.default, .unlock-dialog .button.default,
.login-dialog-button.default, .button.default { background-color: #2BC4B6; color: #0E1230; }
.login-dialog-user-list .user-widget:focus .user-icon,
.login-dialog-user-list .user-widget:selected .user-icon { border-color: #2BC4B6; }
.login-dialog .login-dialog-user-list-view .login-dialog-user-list .login-dialog-user-list-item,
.login-dialog .login-dialog-user-list-view .login-dialog-user-list .login-dialog-user-list-item:hover {
  background-color: rgba(255,255,255,0.07); border-radius: 14px; }
.login-dialog .login-dialog-user-list-view .login-dialog-user-list .login-dialog-user-list-item:focus,
.login-dialog .login-dialog-user-list-view .login-dialog-user-list .login-dialog-user-list-item:selected,
.login-dialog .login-dialog-user-list-view .login-dialog-user-list:expanded .login-dialog-user-list-item:focus {
  background-color: rgba(43,196,182,0.14); border-color: #2BC4B6; box-shadow: inset 0 0 0 2px #2BC4B6; }
.login-dialog-not-listed-label { color: #B9B6D9; }
EOF
)
# ganti aksen oranye Ubuntu (Yaru) jadi teal Kirana di semua CSS
find "$W" -name "*.css" -exec sed -i -e 's/#ef8661/#2bc4b6/Ig' -e 's/#e95420/#2bc4b6/Ig' \
  -e 's/#433c39/#1d3a48/Ig' -e 's/#4c4543/#23485a/Ig' {} +
for f in gdm.css Yaru/gnome-shell.css Yaru/gnome-shell-dark.css; do echo "$CSS" >> "$W/$f"; done
( cd "$W"
  { echo '<?xml version="1.0" encoding="UTF-8"?><gresources><gresource prefix="/org/gnome/shell/theme">'
    find . -type f | sed 's|^\./||' | while read f; do echo "<file>$f</file>"; done
    echo '</gresource></gresources>'; } > kirana.gresource.xml
  glib-compile-resources kirana.gresource.xml )
sudo install -Dm644 "$W/kirana.gresource" /usr/share/gnome-shell/theme/kirana/kirana-gdm.gresource
sudo update-alternatives --quiet --install /usr/share/gnome-shell/gdm-theme.gresource gdm-theme.gresource \
  /usr/share/gnome-shell/theme/kirana/kirana-gdm.gresource 100
sudo update-alternatives --quiet --set gdm-theme.gresource /usr/share/gnome-shell/theme/kirana/kirana-gdm.gresource

echo "[3/3] Pengaturan GDM (dconf): logo, gelap, ikon, kursor, font"
sudo mkdir -p /etc/dconf/db/gdm.d
sudo tee /etc/dconf/db/gdm.d/01-kirana >/dev/null <<EOF
[org/gnome/login-screen]
logo='$B/logo-login.png'
banner-message-enable=false

[org/gnome/desktop/interface]
color-scheme='prefer-dark'
icon-theme='Papirus-Dark'
cursor-theme='Bibata-Modern-Ice'
font-name='Inter 11'
clock-show-weekday=true
EOF
[ -f /etc/dconf/profile/gdm ] || sudo tee /etc/dconf/profile/gdm >/dev/null <<'EOF'
user-db:user
system-db:gdm
file-db:/usr/share/gdm/greeter-dconf-defaults
EOF
sudo dconf update
rm -rf "$TMP"
echo "Login screen selesai (terlihat setelah logout/reboot)."
