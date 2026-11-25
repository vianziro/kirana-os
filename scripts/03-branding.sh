#!/bin/bash
# Kirana OS - 03: Identitas OS (nama, versi, logo di About, hostname)
# ID=kirana dengan ID_LIKE="ubuntu debian" (cara yang sama dipakai Linux Mint & Pop!_OS).
# VERSION_CODENAME/UBUNTU_CODENAME tetap noble agar apt dan repositori tetap jalan.
set -e
HERE="$(cd "$(dirname "$0")/.." && pwd)"
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus

NAME="Kirana OS"; VER="1.0"; CODE="Senja"; AUTHOR="vianziro"

echo "[1/5] os-release (dibaca oleh About, neofetch/fastfetch, systemd, dll)"
# /usr/lib/os-release milik paket base-files -> dialihkan (divert) agar tidak ditimpa update
sudo dpkg-divert --quiet --local --rename --add /usr/lib/os-release 2>/dev/null || true
sudo tee /usr/lib/os-release >/dev/null <<EOF
PRETTY_NAME="$NAME $VER ($CODE)"
NAME="$NAME"
VERSION_ID="24.04"
VERSION="$VER ($CODE)"
VERSION_CODENAME=noble
ID=kirana
ID_LIKE="ubuntu debian"
HOME_URL="https://kirana-os.local/"
SUPPORT_URL="https://kirana-os.local/support"
BUG_REPORT_URL="https://kirana-os.local/bugs"
UBUNTU_CODENAME=noble
LOGO=kirana-logo
BUILD_ID="2026.11 · built by $AUTHOR"
VENDOR_NAME="$AUTHOR"
EOF
sudo ln -sf ../usr/lib/os-release /etc/os-release

echo "[2/5] lsb-release dan pesan login konsol"
sudo tee /etc/lsb-release >/dev/null <<EOF
DISTRIB_ID=Kirana
DISTRIB_RELEASE=24.04
DISTRIB_CODENAME=noble
DISTRIB_DESCRIPTION="$NAME $VER ($CODE)"
EOF
printf "%s\n" "$NAME $VER ($CODE) · built by $AUTHOR \\n \\l" | sudo tee /etc/issue >/dev/null
echo "$NAME $VER ($CODE)" | sudo tee /etc/issue.net >/dev/null
sudo chmod -x /etc/update-motd.d/10-help-text /etc/update-motd.d/50-motd-news 2>/dev/null || true

echo "[3/5] Logo (dipakai halaman About, login, boot)"
A=/usr/share/icons/hicolor
sudo install -Dm644 "$HERE/assets/kirana-logo.svg" $A/scalable/apps/kirana-logo.svg
for s in 48 64 128 256 512; do
  rsvg-convert -w $s "$HERE/assets/kirana-logo.svg" | sudo tee $A/${s}x${s}/apps/kirana-logo.png >/dev/null 2>&1 || {
    sudo mkdir -p $A/${s}x${s}/apps; rsvg-convert -w $s "$HERE/assets/kirana-logo.svg" | sudo tee $A/${s}x${s}/apps/kirana-logo.png >/dev/null; }
done
# halaman About di Ubuntu mencari "<LOGO>-text" / "<LOGO>-text-dark"
sudo install -Dm644 "$HERE/assets/kirana-logo-text-dark.svg" $A/scalable/apps/kirana-logo-text-dark.svg
sed 's/fill="#FFFFFF" letter/fill="#1B1D2A" letter/' "$HERE/assets/kirana-logo-text-dark.svg" | \
  sudo tee $A/scalable/apps/kirana-logo-text.svg >/dev/null
sudo mkdir -p /usr/share/pixmaps
rsvg-convert -w 256 "$HERE/assets/kirana-logo.svg" | sudo tee /usr/share/pixmaps/kirana-logo.png >/dev/null
sudo gtk-update-icon-cache -qf $A

# Settings > About di Ubuntu memakai file ini secara hardcode -> ganti (divert) dengan logo Kirana + kredit
for v in "" "-dark"; do
  FILL=$([ "$v" = "-dark" ] && echo "#FFFFFF" || echo "#1B1D2A")
  LOGO_SVG=$(sed "s/fill=\"#FFFFFF\" letter/fill=\"$FILL\" letter/" "$HERE/assets/kirana-logo-text-dark.svg" | base64 -w0)
  cat > /tmp/about$v.svg <<EOF
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="640" height="220">
<image x="0" y="10" width="640" height="160" xlink:href="data:image/svg+xml;base64,$LOGO_SVG"/>
<text x="360" y="200" text-anchor="middle" font-family="Inter" font-size="22" font-weight="500" fill="#8C88B5" letter-spacing="5">BUILT BY <tspan fill="#FF9A5A">VIANZIRO</tspan></text>
</svg>
EOF
  F=/usr/share/pixmaps/ubuntu-logo-text$v.png
  sudo dpkg-divert --quiet --local --rename --add $F 2>/dev/null || true
  rsvg-convert -w 512 /tmp/about$v.svg | sudo tee $F >/dev/null
  rm -f /tmp/about$v.svg
done

echo "[4/5] Hostname -> kirana"
sudo hostnamectl set-hostname kirana
sudo hostnamectl set-hostname --pretty "Kirana Lab"
sudo sed -i 's/^127\.0\.1\.1.*/127.0.1.1\tkirana/' /etc/hosts
grep -q "127.0.1.1" /etc/hosts || echo -e "127.0.1.1\tkirana" | sudo tee -a /etc/hosts >/dev/null

echo "[5/5] Rapikan: notifikasi tema snap, cache font"
sudo snap disable snapd-desktop-integration >/dev/null 2>&1 || true   # hilangkan notifikasi "themes are missing"
fc-cache -f >/dev/null
echo "Branding selesai: $(. /etc/os-release; echo $PRETTY_NAME)"
