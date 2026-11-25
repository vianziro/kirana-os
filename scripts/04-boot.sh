#!/bin/bash
# Kirana OS - 04: Tampilan boot -> GRUB theme + Plymouth splash (boot & shutdown)
set -e
HERE="$(cd "$(dirname "$0")/.." && pwd)"
LOGO="$HERE/assets/kirana-logo.svg"
TMP=$(mktemp -d)

########## PLYMOUTH ##########
echo "[1/4] Tema Plymouth 'kirana'"
P=/usr/share/plymouth/themes/kirana
sudo mkdir -p $P
sudo cp "$HERE/assets/plymouth/kirana.script" $P/
rsvg-convert -w 140 "$LOGO" -o "$TMP/logo.png"
# caption dua baris: judul + subjudul
cat > "$TMP/hello.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="520" height="90">
<text x="50%" y="40" text-anchor="middle" font-family="Inter" font-size="34" font-weight="700" fill="#FFFFFF">Kirana <tspan font-weight="300" fill="#2BC4B6">OS</tspan></text>
<text x="50%" y="76" text-anchor="middle" font-family="Inter" font-size="17" font-weight="400" fill="#B9B6D9" letter-spacing="2">MEMULAI SISTEM</text></svg>
EOF
sed 's/MEMULAI SISTEM/SAMPAI JUMPA · MEMATIKAN SISTEM/' "$TMP/hello.svg" > "$TMP/bye.svg"
rsvg-convert "$TMP/hello.svg" -o "$TMP/hello.png"
rsvg-convert "$TMP/bye.svg"   -o "$TMP/bye.png"
cat > "$TMP/dot.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12"><circle cx="6" cy="6" r="6" fill="#2BC4B6"/></svg>
EOF
rsvg-convert "$TMP/dot.svg" -o "$TMP/dot.png"
cat > "$TMP/credit.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="360" height="30">
<text x="50%" y="20" text-anchor="middle" font-family="Inter" font-size="13" font-weight="500" fill="#8C88B5" letter-spacing="3">BUILT BY <tspan fill="#FF9A5A">VIANZIRO</tspan></text></svg>
EOF
rsvg-convert "$TMP/credit.svg" -o "$TMP/credit.png"
sudo cp "$TMP"/{logo,hello,bye,dot,credit}.png $P/
sudo tee $P/kirana.plymouth >/dev/null <<EOF
[Plymouth Theme]
Name=Kirana OS
Description=Splash Kirana OS untuk boot dan shutdown
ModuleName=script

[script]
ImageDir=$P
ScriptFile=$P/kirana.script
EOF
sudo update-alternatives --quiet --install /usr/share/plymouth/themes/default.plymouth \
  default.plymouth $P/kirana.plymouth 200
sudo update-alternatives --quiet --set default.plymouth $P/kirana.plymouth
echo FRAMEBUFFER=y | sudo tee /etc/initramfs-tools/conf.d/splash >/dev/null

########## GRUB ##########
echo "[2/4] Tema GRUB 'kirana'"
G=/boot/grub/themes/kirana
sudo mkdir -p $G
# latar GRUB: gradasi gelap + logo + pegunungan
LOGO_INNER=$(sed -n '/<defs>/,/<\/svg>/p' "$LOGO" | sed '$d')
cat > "$TMP/grub-bg.svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1920 1080" width="1920" height="1080">
<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#0E1230"/><stop offset="1" stop-color="#2A1C4F"/></linearGradient></defs>
<rect width="1920" height="1080" fill="url(#g)"/>
<path d="M0 960 L450 840 L850 1000 L1300 870 L1920 1010 L1920 1080 L0 1080 Z" fill="#120F2E"/>
<path d="M0 960 L450 840 L850 1000 L1300 870 L1920 1010" stroke="#2BC4B6" stroke-width="3" fill="none" opacity=".8"/>
<g transform="translate(896,150) scale(0.5)">$LOGO_INNER</g>
<text x="960" y="330" text-anchor="middle" font-family="Inter" font-size="44" font-weight="700" fill="#FFFFFF">Kirana <tspan font-weight="300" fill="#2BC4B6">OS</tspan></text>
</svg>
EOF
rsvg-convert "$TMP/grub-bg.svg" -o "$TMP/background.png"
sudo cp "$TMP/background.png" $G/
# bingkai item terpilih (kapsul teal transparan)
for part in c w e; do
  W=$([ $part = c ] && echo 8 || echo 12)
  R=$([ $part = c ] && echo 0 || echo 12)
  X=$([ $part = e ] && echo -12 || echo 0)
  cat > "$TMP/s.svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="$W" height="44"><rect x="$X" y="0" width="24" height="44" rx="$R" fill="#2BC4B6" fill-opacity="0.22"/></svg>
EOF
  rsvg-convert "$TMP/s.svg" -o "$TMP/select_$part.png"; sudo cp "$TMP/select_$part.png" $G/
done
# font GRUB dari Inter
sudo grub-mkfont -s 20 -n "Inter Regular 20" -o $G/inter20.pf2 /usr/share/fonts/opentype/inter/Inter-Regular.otf
sudo grub-mkfont -s 16 -n "Inter Regular 16" -o $G/inter16.pf2 /usr/share/fonts/opentype/inter/Inter-Regular.otf
sudo tee $G/theme.txt >/dev/null <<'EOF'
# Kirana OS GRUB theme
title-text: ""
desktop-image: "background.png"
desktop-color: "#0E1230"
terminal-font: "Inter Regular 16"

+ boot_menu {
  left = 30%
  top = 40%
  width = 40%
  height = 36%
  item_font = "Inter Regular 20"
  item_color = "#B9B6D9"
  selected_item_font = "Inter Regular 20"
  selected_item_color = "#FFFFFF"
  selected_item_pixmap_style = "select_*.png"
  item_height = 44
  item_padding = 16
  item_spacing = 6
  scrollbar = false
}

+ label {
  left = 0
  top = 84%
  width = 100%
  align = "center"
  id = "__timeout__"
  text = "Masuk otomatis dalam %d detik  ·  ↑↓ pilih  ·  Enter jalankan"
  font = "Inter Regular 16"
  color = "#8C88B5"
}

+ label {
  left = 0
  top = 95%
  width = 100%
  align = "center"
  text = "Kirana OS 1.0 Senja  ·  built by vianziro"
  font = "Inter Regular 16"
  color = "#FF9A5A"
}
EOF

echo "[3/4] Konfigurasi GRUB: tampilkan menu 5 detik + pakai tema"
sudo sed -i \
  -e 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/' \
  -e 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/' \
  -e 's/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="Kirana OS"/' /etc/default/grub
sudo sed -i '/^GRUB_THEME=/d;/^GRUB_GFXMODE=/d;/^GRUB_GFXPAYLOAD_LINUX=/d' /etc/default/grub
cat <<EOF | sudo tee -a /etc/default/grub >/dev/null
GRUB_THEME="$G/theme.txt"
GRUB_GFXMODE=1920x1080,1280x800,auto
GRUB_GFXPAYLOAD_LINUX=keep
EOF
# Ubuntu menyembunyikan menu GRUB bila hanya 1 OS; paksa tampil
echo 'GRUB_RECORDFAIL_TIMEOUT=5' | sudo tee /etc/default/grub.d/99-kirana.cfg >/dev/null

echo "[4/4] Terapkan (update-grub + initramfs)"
sudo update-grub 2>&1 | grep -E "Found|done" | head -4
sudo update-initramfs -u >/dev/null 2>&1
rm -rf "$TMP"
echo "Boot theme selesai."
