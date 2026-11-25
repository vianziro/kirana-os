#!/usr/bin/env bash
# Kirana OS - bangun semua paket .deb ke dist/
# Jalan di Ubuntu 24.04 (lokal atau GitHub Actions). Butuh:
#   dpkg-dev git curl unzip xz-utils python3 librsvg2-bin grub-common sassc fonts-inter
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
VER=$(cat "$ROOT/packaging/VERSION")
OUT=${OUT:-$ROOT/dist}
WORK=${WORK:-$ROOT/build}
A=$ROOT/assets
P=$ROOT/packaging
MAINT="vianziro <vianziro@users.noreply.github.com>"
HOMEPAGE="https://github.com/vianziro/kirana-os"

# Komponen pihak ketiga - versi DIKUNCI agar build bisa diulang
ORCHIS_COMMIT=a4c48a425e63808345e824495964bd9c2f462e04   # GPL-3.0
BIBATA_VER=v2.0.7                                        # GPL-3.0
TILINGSHELL_TAG=76684                                    # Tiling Shell v77, GPL-2.0, GNOME 46

rm -rf "$WORK"; mkdir -p "$WORK/src" "$OUT"
log() { echo "==> $*"; }

stage() { mkdir -p "$WORK/$1/DEBIAN"; echo "$WORK/$1"; }

control() { # dir pkg depends recommends ringkas panjang
  {
    echo "Package: $2"
    echo "Version: $VER"
    echo "Architecture: all"
    echo "Maintainer: $MAINT"
    echo "Homepage: $HOMEPAGE"
    echo "Section: misc"
    echo "Priority: optional"
    [ -n "$3" ] && echo "Depends: $3"
    [ -n "$4" ] && echo "Recommends: $4"
    echo "Description: $5"
    echo " $6"
  } > "$1/DEBIAN/control"
}

finish() { # dir pkg  -> maintainer scripts, conffiles, copyright, build
  local d=$1 pkg=$2 s
  for s in preinst postinst prerm postrm; do
    [ -f "$P/$pkg/$s" ] && install -m755 "$P/$pkg/$s" "$d/DEBIAN/$s"
  done
  [ -f "$P/$pkg/triggers" ] && install -m644 "$P/$pkg/triggers" "$d/DEBIAN/triggers"
  if [ -d "$d/etc" ]; then
    (cd "$d" && find etc -type f | sed 's|^|/|' | sort) > "$d/DEBIAN/conffiles"
  fi
  install -Dm644 "$ROOT/packaging/copyright" "$d/usr/share/doc/$pkg/copyright"
  find "$d" -type d -exec chmod 755 {} +
  dpkg-deb --root-owner-group -Zxz --build "$d" "$OUT/" >/dev/null
  log "selesai: ${pkg}_${VER}_all.deb"
}

svg() { rsvg-convert "$@"; }

###############################################################################
log "kirana-tools"
D=$(stage kirana-tools)
for b in kirana kirana-theme kirana-keys kirana-widget; do install -Dm755 "$A/bin/$b" "$D/usr/bin/$b"; done
install -Dm644 -t "$D/usr/share/kirana/themes" "$A"/themes/*.theme
install -Dm644 -t "$D/usr/share/kirana" "$A/shell/kirana-shell.css" "$A/kirana-logo.svg" "$A/wallpaper.svg"
install -Dm644 -t "$D/etc/kirana" "$A/config/starship.toml" "$A/config/fastfetch.jsonc" "$A/config/logo.txt"
install -Dm644 "$A/conky/kirana.conf" "$D/etc/kirana/conky.conf"
install -Dm755 "$A/config/greet.sh" "$D/etc/kirana/greet.sh"
install -Dm644 "$A/config/kirana-shell.sh" "$D/etc/profile.d/kirana-shell.sh"
install -d "$D/etc/xdg/autostart" "$D/usr/share/applications"
cat > "$D/etc/xdg/autostart/kirana-widget.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Kirana Widget
Exec=sh -c "sleep 4; exec kirana-widget"
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF
cat > "$D/usr/share/applications/kirana-theme.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Kirana Theme
Comment=Ganti tema Kirana OS
Exec=kirana-theme
Icon=kirana-logo
Categories=Settings;
EOF
cat > "$D/usr/share/applications/kirana-keys.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Shortcut Kirana
Comment=Contekan shortcut keyboard
Exec=kirana-keys
Icon=input-keyboard
Categories=Utility;
EOF
control "$D" kirana-tools \
  "conky-all, zenity, python3, python3-gi, gir1.2-gtk-4.0, librsvg2-bin, libnotify-bin, dconf-cli, procps" \
  "fastfetch, starship, kirana-themes" \
  "Kirana OS - alat baris perintah dan desktop" \
  "Perintah kirana, kirana-theme, kirana-keys, widget desktop, prompt dan fastfetch."
finish "$D" kirana-tools

###############################################################################
log "kirana-themes (Orchis, Bibata, Tiling Shell, wallpaper)"
D=$(stage kirana-themes)
S=$WORK/src
git -c init.defaultBranch=main init -q "$S/orchis"
git -C "$S/orchis" fetch -q --depth 1 https://github.com/vinceliuice/Orchis-theme "$ORCHIS_COMMIT"
git -C "$S/orchis" checkout -q FETCH_HEAD
OPTS=(-c dark -s standard -i simple --round 10px --shell 46)
for t in default purple orange teal; do
  bash "$S/orchis/install.sh" -d "$D/usr/share/themes" -t "$t" "${OPTS[@]}" --tweaks solid >/dev/null
done
bash "$S/orchis/install.sh" -d "$D/usr/share/themes" -t default "${OPTS[@]}" --tweaks solid nord >/dev/null
# tema shell bawaan "Kirana" = Orchis-Teal-Dark + CSS Kirana
cp -r "$D/usr/share/themes/Orchis-Teal-Dark/gnome-shell" "$WORK/kirana-shell"
install -d "$D/usr/share/themes/Kirana"
mv "$WORK/kirana-shell" "$D/usr/share/themes/Kirana/gnome-shell"
cat "$A/shell/kirana-shell.css" >> "$D/usr/share/themes/Kirana/gnome-shell/gnome-shell.css"
cp "$A/kirana-logo.svg" "$D/usr/share/themes/Kirana/gnome-shell/"

curl -fsSL -o "$S/bibata.tar.xz" "https://github.com/ful1e5/Bibata_Cursor/releases/download/$BIBATA_VER/Bibata-Modern-Ice.tar.xz"
install -d "$D/usr/share/icons"; tar -xf "$S/bibata.tar.xz" -C "$D/usr/share/icons"

TS=tilingshell@ferrarodomenico.com
curl -fsSL -o "$S/ts.zip" "https://extensions.gnome.org/download-extension/$TS.shell-extension.zip?version_tag=$TILINGSHELL_TAG"
install -d "$D/usr/share/gnome-shell/extensions/$TS"
unzip -qo "$S/ts.zip" -d "$D/usr/share/gnome-shell/extensions/$TS"
rm -f "$D/usr/share/gnome-shell/extensions/$TS/schemas/gschemas.compiled"
install -Dm644 "$D/usr/share/gnome-shell/extensions/$TS/schemas/org.gnome.shell.extensions.tilingshell.gschema.xml" \
  "$D/usr/share/glib-2.0/schemas/org.gnome.shell.extensions.tilingshell.gschema.xml"
rm -rf "$D/usr/share/gnome-shell/extensions/$TS/schemas"

BG=$D/usr/share/backgrounds/kirana
install -d "$BG" "$D/usr/share/gnome-background-properties"
python3 "$A/wallpaper/make_variants.py" "$A/wallpaper.svg" "$S/wp" >/dev/null
for v in pagi siang senja malam; do svg -w 2560 -h 1440 "$S/wp/$v.svg" -o "$BG/$v.png"; done
cp "$A/wallpaper.svg" "$BG/senja.svg"
st()  { echo "  <static><duration>$1</duration><file>/usr/share/backgrounds/kirana/$2.png</file></static>"; }
trn() { echo "  <transition type=\"overlay\"><duration>1800</duration><from>/usr/share/backgrounds/kirana/$1.png</from><to>/usr/share/backgrounds/kirana/$2.png</to></transition>"; }
{ echo "<background>"
  echo "  <starttime><year>2026</year><month>1</month><day>1</day><hour>5</hour><minute>0</minute><second>0</second></starttime>"
  st 16200 pagi; trn pagi siang; st 19800 siang; trn siang senja
  st 5400 senja; trn senja malam; st 37800 malam; trn malam pagi
  echo "</background>"; } > "$BG/kirana-dinamis.xml"
{ echo '<?xml version="1.0"?>'; echo '<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">'; echo '<wallpapers>'
  echo '  <wallpaper deleted="false"><name>Kirana Dinamis</name><filename>/usr/share/backgrounds/kirana/kirana-dinamis.xml</filename><options>zoom</options></wallpaper>'
  for v in Pagi Siang Senja Malam; do l=${v,,}
    echo "  <wallpaper deleted=\"false\"><name>Kirana $v</name><filename>/usr/share/backgrounds/kirana/$l.png</filename><options>zoom</options></wallpaper>"; done
  echo '</wallpapers>'; } > "$D/usr/share/gnome-background-properties/kirana.xml"
control "$D" kirana-themes \
  "papirus-icon-theme, fonts-inter, fonts-jetbrains-mono, gnome-shell-extensions" "" \
  "Kirana OS - tema, ikon kursor, ekstensi tiling, dan wallpaper" \
  "Tema Orchis (Senja/Nord/Catppuccin/Gruvbox/Tokyo Night), Bibata, Tiling Shell, wallpaper dinamis."
finish "$D" kirana-themes

###############################################################################
log "kirana-branding"
D=$(stage kirana-branding)
T=$WORK/tmp; mkdir -p "$T"
install -Dm755 "$P/kirana-branding/lib/rebrand" "$D/usr/lib/kirana/rebrand"
install -Dm755 "$P/kirana-branding/lib/build-gdm-theme" "$D/usr/lib/kirana/build-gdm-theme"
R=$D/usr/share/kirana/branding/replace

# identitas OS
install -d "$R/usr/lib" "$R/etc/apt/apt.conf.d" "$R/usr/share/pixmaps" "$R/usr/share/gnome-background-properties"
cat > "$R/usr/lib/os-release" <<EOF
PRETTY_NAME="Kirana OS ${VER%.*} (Senja)"
NAME="Kirana OS"
VERSION_ID="${VER%.*}"
VERSION="${VER%.*} (Senja)"
VERSION_CODENAME=noble
ID=kirana
ID_LIKE="ubuntu debian"
HOME_URL="$HOMEPAGE"
SUPPORT_URL="$HOMEPAGE/blob/main/docs/PANDUAN.md"
BUG_REPORT_URL="$HOMEPAGE/issues"
UBUNTU_CODENAME=noble
LOGO=kirana-logo
BUILD_ID="$VER · built by vianziro"
VENDOR_NAME="vianziro"
EOF
cat > "$R/etc/lsb-release" <<EOF
DISTRIB_ID=Kirana
DISTRIB_RELEASE=${VER%.*}
DISTRIB_CODENAME=noble
DISTRIB_DESCRIPTION="Kirana OS ${VER%.*} (Senja)"
EOF
printf 'Kirana OS %s (Senja) \\n \\l\n\n' "${VER%.*}" > "$R/etc/issue"
printf 'Kirana OS %s (Senja)\n' "${VER%.*}" > "$R/etc/issue.net"
printf '\nKirana OS - built by vianziro\nPerangkat lunak di sistem ini adalah perangkat lunak bebas;\nlisensi tiap program ada di /usr/share/doc/*/copyright.\n\n' > "$R/etc/legal"
echo '// Kirana OS: iklan Ubuntu Pro di apt dinonaktifkan' > "$R/etc/apt/apt.conf.d/20apt-esm-hook.conf"
for x in noble-wallpapers.xml ubuntu-wallpapers.xml; do
  printf '<?xml version="1.0"?>\n<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">\n<wallpapers/>\n' > "$R/usr/share/gnome-background-properties/$x"
done

# logo
H=$D/usr/share/icons/hicolor
install -Dm644 "$A/kirana-logo.svg" "$H/scalable/apps/kirana-logo.svg"
install -Dm644 "$A/kirana-logo-text-dark.svg" "$H/scalable/apps/kirana-logo-text-dark.svg"
sed 's/fill="#FFFFFF" letter/fill="#1B1D2A" letter/' "$A/kirana-logo-text-dark.svg" > "$H/scalable/apps/kirana-logo-text.svg"
for s in 48 64 128 256 512; do install -d "$H/${s}x${s}/apps"; svg -w $s "$A/kirana-logo.svg" -o "$H/${s}x${s}/apps/kirana-logo.png"; done
install -d "$D/usr/share/pixmaps"; svg -w 256 "$A/kirana-logo.svg" -o "$D/usr/share/pixmaps/kirana-logo.png"
# logo halaman Settings > About (path hardcode Ubuntu) + kredit
for v in "" "-dark"; do
  FILL=$([ "$v" = "-dark" ] && echo "#FFFFFF" || echo "#1B1D2A")
  LS=$(sed "s/fill=\"#FFFFFF\" letter/fill=\"$FILL\" letter/" "$A/kirana-logo-text-dark.svg" | base64 -w0)
  cat > "$T/about$v.svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="640" height="220">
<image x="0" y="10" width="640" height="160" xlink:href="data:image/svg+xml;base64,$LS"/>
<text x="360" y="200" text-anchor="middle" font-family="Inter" font-size="22" font-weight="500" fill="#8C88B5" letter-spacing="5">BUILT BY <tspan fill="#FF9A5A">VIANZIRO</tspan></text>
</svg>
EOF
  svg -w 512 "$T/about$v.svg" -o "$R/usr/share/pixmaps/ubuntu-logo-text$v.png"
done

# Plymouth: splash boot/shutdown + mode teks
PL=$D/usr/share/plymouth/themes/kirana
install -Dm644 "$A/plymouth/kirana.script" "$PL/kirana.script"
svg -w 140 "$A/kirana-logo.svg" -o "$PL/logo.png"
cat > "$T/hello.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="520" height="90">
<text x="50%" y="40" text-anchor="middle" font-family="Inter" font-size="34" font-weight="700" fill="#FFFFFF">Kirana <tspan font-weight="300" fill="#2BC4B6">OS</tspan></text>
<text x="50%" y="76" text-anchor="middle" font-family="Inter" font-size="17" font-weight="400" fill="#B9B6D9" letter-spacing="2">MEMULAI SISTEM</text></svg>
EOF
sed 's/MEMULAI SISTEM/SAMPAI JUMPA · MEMATIKAN SISTEM/' "$T/hello.svg" > "$T/bye.svg"
echo '<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12"><circle cx="6" cy="6" r="6" fill="#2BC4B6"/></svg>' > "$T/dot.svg"
cat > "$T/credit.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="360" height="30">
<text x="50%" y="20" text-anchor="middle" font-family="Inter" font-size="13" font-weight="500" fill="#8C88B5" letter-spacing="3">BUILT BY <tspan fill="#FF9A5A">VIANZIRO</tspan></text></svg>
EOF
for x in hello bye dot credit; do svg "$T/$x.svg" -o "$PL/$x.png"; done
cat > "$PL/kirana.plymouth" <<'EOF'
[Plymouth Theme]
Name=Kirana OS
Description=Splash Kirana OS untuk boot dan shutdown
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/kirana
ScriptFile=/usr/share/plymouth/themes/kirana/kirana.script
EOF
install -d "$D/usr/share/plymouth/themes/kirana-text"
cat > "$D/usr/share/plymouth/themes/kirana-text/kirana-text.plymouth" <<EOF
[Plymouth Theme]
Name=Kirana Text
Description=Splash mode teks Kirana OS
ModuleName=ubuntu-text

[ubuntu-text]
title=Kirana OS ${VER%.*} Senja
black=0x0e1230
white=0xffffff
brown=0x2bc4b6
blue=0x8c88b5
EOF

# GRUB
G=$D/usr/share/kirana/grub/kirana; install -d "$G"
LOGO_INNER=$(sed -n '/<defs>/,/<\/svg>/p' "$A/kirana-logo.svg" | sed '$d')
cat > "$T/grub-bg.svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1920 1080" width="1920" height="1080">
<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0E1230"/><stop offset="1" stop-color="#2A1C4F"/></linearGradient></defs>
<rect width="1920" height="1080" fill="url(#g)"/>
<path d="M0 960 L450 840 L850 1000 L1300 870 L1920 1010 L1920 1080 L0 1080 Z" fill="#120F2E"/>
<path d="M0 960 L450 840 L850 1000 L1300 870 L1920 1010" stroke="#2BC4B6" stroke-width="3" fill="none" opacity=".8"/>
<g transform="translate(896,150) scale(0.5)">$LOGO_INNER</g>
<text x="960" y="330" text-anchor="middle" font-family="Inter" font-size="44" font-weight="700" fill="#FFFFFF">Kirana <tspan font-weight="300" fill="#2BC4B6">OS</tspan></text>
</svg>
EOF
svg "$T/grub-bg.svg" -o "$G/background.png"
for part in c w e; do
  W=$([ $part = c ] && echo 8 || echo 12); RR=$([ $part = c ] && echo 0 || echo 12); X=$([ $part = e ] && echo -12 || echo 0)
  echo "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$W\" height=\"44\"><rect x=\"$X\" y=\"0\" width=\"24\" height=\"44\" rx=\"$RR\" fill=\"#2BC4B6\" fill-opacity=\"0.22\"/></svg>" > "$T/s.svg"
  svg "$T/s.svg" -o "$G/select_$part.png"
done
INTER=$(fc-match -f '%{file}' 'Inter:style=Regular')
grub-mkfont -s 20 -n "Inter Regular 20" -o "$G/inter20.pf2" "$INTER" 2>/dev/null
grub-mkfont -s 16 -n "Inter Regular 16" -o "$G/inter16.pf2" "$INTER" 2>/dev/null
cat > "$G/theme.txt" <<EOF
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
  text = "Kirana OS ${VER%.*} Senja  ·  built by vianziro"
  font = "Inter Regular 16"
  color = "#FF9A5A"
}
EOF
install -d "$D/etc/default/grub.d"
cat > "$D/etc/default/grub.d/90-kirana.cfg" <<'EOF'
# Kirana OS
GRUB_DISTRIBUTOR="Kirana OS"
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=5
GRUB_RECORDFAIL_TIMEOUT=5
GRUB_THEME=/boot/grub/themes/kirana/theme.txt
GRUB_GFXMODE=1920x1080,1280x800,auto
GRUB_GFXPAYLOAD_LINUX=keep
EOF

# GDM (layar login)
GD=$D/usr/share/kirana/gdm; install -d "$GD"
svg -w 2560 -h 1440 "$S/wp/senja.svg" -o "$T/senja.png" 2>/dev/null || svg -w 2560 -h 1440 "$A/wallpaper.svg" -o "$T/senja.png"
IMG="data:image/png;base64,$(base64 -w0 "$T/senja.png")"
cat > "$T/login.svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1920" height="1080">
<defs><filter id="b" x="-200" y="-200" width="2320" height="1480" filterUnits="userSpaceOnUse"><feGaussianBlur stdDeviation="28"/></filter></defs>
<rect width="1920" height="1080" fill="#0E1230"/><image x="-160" y="-160" width="2240" height="1400" xlink:href="$IMG" preserveAspectRatio="xMidYMid slice" filter="url(#b)"/>
<rect width="1920" height="1080" fill="#0E1230" fill-opacity="0.45"/>
</svg>
EOF
svg "$T/login.svg" -o "$GD/login.png"
LT=$(base64 -w0 "$A/kirana-logo-text-dark.svg")
cat > "$T/logo-login.svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="320" height="104">
<image x="0" y="0" width="320" height="80" xlink:href="data:image/svg+xml;base64,$LT"/>
<text x="160" y="98" text-anchor="middle" font-family="Inter" font-size="12" font-weight="500" fill="#8C88B5" letter-spacing="3">BUILT BY <tspan fill="#FF9A5A">VIANZIRO</tspan></text>
</svg>
EOF
svg -h 72 "$T/logo-login.svg" -o "$GD/logo-login.png"
cat > "$GD/kirana-gdm.css" <<'EOF'

/* ===== Kirana OS (layar login) ===== */
#lockDialogGroup {
  background: #0E1230 url(file:///usr/share/kirana/gdm/login.png);
  background-size: cover; background-position: center; }
.login-dialog-prompt-entry, .unlock-dialog .login-dialog-prompt-entry { border-radius: 12px; }
.login-dialog .button.default, .unlock-dialog .button.default,
.login-dialog-button.default, .button.default { background-color: #2BC4B6; color: #0E1230; }
.login-dialog .login-dialog-user-list-view .login-dialog-user-list .login-dialog-user-list-item,
.login-dialog .login-dialog-user-list-view .login-dialog-user-list .login-dialog-user-list-item:hover {
  background-color: rgba(255,255,255,0.07); border-radius: 14px; }
.login-dialog .login-dialog-user-list-view .login-dialog-user-list .login-dialog-user-list-item:focus,
.login-dialog .login-dialog-user-list-view .login-dialog-user-list .login-dialog-user-list-item:selected {
  background-color: rgba(43,196,182,0.14); border-color: #2BC4B6; box-shadow: inset 0 0 0 2px #2BC4B6; }
.login-dialog-not-listed-label { color: #B9B6D9; }
EOF
install -d "$D/etc/dconf/db/gdm.d"
cat > "$D/etc/dconf/db/gdm.d/90-kirana" <<'EOF'
[org/gnome/login-screen]
logo='/usr/share/kirana/gdm/logo-login.png'
banner-message-enable=false

[org/gnome/desktop/interface]
color-scheme='prefer-dark'
icon-theme='Papirus-Dark'
cursor-theme='Bibata-Modern-Ice'
font-name='Inter 11'
clock-show-weekday=true

[org/gnome/desktop/sound]
theme-name='freedesktop'
EOF

# Firefox: beranda Kirana + privasi
install -Dm644 "$A/start/index.html" "$D/usr/share/kirana/start/index.html"
sed -i 's|file:///usr/share/kirana/README.html|https://github.com/vianziro/kirana-os/blob/main/docs/PANDUAN.md|' "$D/usr/share/kirana/start/index.html"
install -d "$D/etc/firefox/policies"
cat > "$D/etc/firefox/policies/policies.json" <<'EOF'
{
  "policies": {
    "Homepage": { "URL": "file:///usr/share/kirana/start/index.html", "StartPage": "homepage", "Locked": false },
    "DisableTelemetry": true,
    "DisableFirefoxStudies": true,
    "DisablePocket": true,
    "DontCheckDefaultBrowser": true,
    "OverrideFirstRunPage": "",
    "OverridePostUpdatePage": "",
    "FirefoxHome": { "SponsoredTopSites": false, "SponsoredPocket": false, "Pocket": false, "Locked": false },
    "UserMessaging": { "WhatsNew": false, "ExtensionRecommendations": false, "FeatureRecommendations": false, "SkipOnboarding": true, "MoreFromMozilla": false }
  }
}
EOF

# Update keamanan tetap jalan walau ID distro = Kirana
install -d "$D/etc/apt/apt.conf.d"
cat > "$D/etc/apt/apt.conf.d/52kirana-unattended-upgrades" <<'EOF'
// Kirana OS memakai arsip Ubuntu, tapi lsb_release melaporkan "Kirana".
// Pola asal eksplisit ini memastikan unattended-upgrades tetap memasang update keamanan Ubuntu.
Unattended-Upgrade::Origins-Pattern {
        "origin=Ubuntu,archive=${distro_codename}-security,label=Ubuntu";
        "origin=UbuntuESMApps,archive=${distro_codename}-apps-security";
        "origin=UbuntuESM,archive=${distro_codename}-infra-security";
};
EOF

control "$D" kirana-branding \
  "plymouth, plymouth-theme-ubuntu-text, grub-common, libglib2.0-bin, libglib2.0-dev-bin, dconf-cli" "" \
  "Kirana OS - identitas distro (boot, login, About)" \
  "os-release, logo, GRUB, Plymouth, layar login, beranda Firefox; file Ubuntu dialihkan dengan dpkg-divert."
finish "$D" kirana-branding

###############################################################################
log "kirana-vm"
D=$(stage kirana-vm)
install -d "$D/usr/sbin"
cat > "$D/usr/sbin/kirana-display-refresh" <<'EOF'
#!/bin/sh
# Dipanggil pam_exec saat sesi GDM dibuka (VirtualBox): gambar ulang layar
# dengan pindah konsol sebentar, agar layar tidak membeku di gambar layar login.
[ "$PAM_TYPE" = "open_session" ] || exit 0
(
  sleep 4
  V=$(sed 's/tty//' /sys/class/tty/tty0/active 2>/dev/null)
  [ -n "$V" ] || exit 0
  chvt 63; sleep 0.4; chvt "$V"
) </dev/null >/dev/null 2>&1 &
exit 0
EOF
chmod 755 "$D/usr/sbin/kirana-display-refresh"
control "$D" kirana-vm "systemd, kbd" "" \
  "Kirana OS - perbaikan khusus VirtualBox" \
  "Hanya aktif bila berjalan di VirtualBox: sesi X11 dan perbaikan layar beku setelah login."
finish "$D" kirana-vm

###############################################################################
log "kirana-desktop (metapaket + pengaturan bawaan)"
D=$(stage kirana-desktop)
install -Dm644 "$A/dconf/90-kirana" "$D/etc/dconf/db/local.d/90-kirana"
install -d "$D/etc/dconf/profile"
printf 'user-db:user\nsystem-db:local\n' > "$D/etc/dconf/profile/user"
install -d "$D/etc/systemd/journald.conf.d" "$D/etc/sysctl.d"
printf '[Journal]\nSystemMaxUse=100M\nRuntimeMaxUse=30M\n' > "$D/etc/systemd/journald.conf.d/90-kirana.conf"
printf '# Kirana OS: zram lebih murah daripada membuang cache\nvm.swappiness=100\nvm.vfs_cache_pressure=50\nvm.page-cluster=0\n' > "$D/etc/sysctl.d/90-kirana.conf"
V="(= $VER)"
control "$D" kirana-desktop \
  "kirana-branding $V, kirana-themes $V, kirana-tools $V, zram-tools, dconf-cli, gnome-shell-extensions" \
  "kirana-vm, fastfetch, starship" \
  "Kirana OS - desktop lengkap" \
  "Metapaket Kirana OS: memasang semua komponen dan pengaturan bawaan desktop."
finish "$D" kirana-desktop

ls -la "$OUT"
