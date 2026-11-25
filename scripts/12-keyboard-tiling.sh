#!/bin/bash
# Kirana OS - 12: Keyboard-first + auto-tiling (terinspirasi Omarchy & Pop!_OS)
#   - shortcut: Super+Enter terminal, Super+B browser, Super+F file, Super+Q tutup, Super+1..4 workspace
#   - Tiling Shell: auto-tiling, gap, border warna aksen pada jendela aktif
#   - Super+/ contekan shortcut, Super+Shift+T pemilih tema
set -e
HERE="$(cd "$(dirname "$0")/.." && pwd)"
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus

echo "[1/4] Alat contekan"
sudo install -m755 "$HERE/assets/bin/kirana-keys" /usr/local/bin/kirana-keys

echo "[2/4] Workspace tetap 4 + shortcut jendela"
WM=org.gnome.desktop.wm.keybindings
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.mutter center-new-windows true          # jendela baru muncul di tengah
gsettings set org.gnome.desktop.wm.preferences num-workspaces 4
gsettings set org.gnome.shell.extensions.dash-to-dock hot-keys false   # bebaskan Super+angka
for i in 1 2 3 4; do
  gsettings set org.gnome.shell.keybindings switch-to-application-$i "[]"
  gsettings set $WM switch-to-workspace-$i "['<Super>$i']"
  gsettings set $WM move-to-workspace-$i "['<Super><Shift>$i']"
done
gsettings set $WM close "['<Super>q', '<Alt>F4']"
gsettings set $WM switch-input-source "[]"
gsettings set $WM switch-input-source-backward "[]"
gsettings set org.gnome.shell.keybindings toggle-overview "['<Super>space']"
gsettings set org.gnome.shell.keybindings show-screenshot-ui "['Print', '<Super><Shift>s']"

echo "[3/4] Shortcut aplikasi"
K=org.gnome.settings-daemon.plugins.media-keys
B=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings
add() { # id nama perintah tombol
  gsettings set $K.custom-keybinding:$B/$1/ name "$2"
  gsettings set $K.custom-keybinding:$B/$1/ command "$3"
  gsettings set $K.custom-keybinding:$B/$1/ binding "$4"
}
add kirana-term  "Terminal"      "gnome-terminal"          "<Super>Return"
add kirana-web   "Browser"       "firefox"                 "<Super>b"
add kirana-files "File"          "nautilus --new-window"   "<Super>f"
add kirana-keys  "Contekan"      "kirana-keys"             "<Super>slash"
add kirana-theme "Ganti tema"    "kirana-theme"            "<Super><Shift>t"
gsettings set $K custom-keybindings "['$B/kirana-term/', '$B/kirana-web/', '$B/kirana-files/', '$B/kirana-keys/', '$B/kirana-theme/']"

echo "[4/4] Tiling Shell (auto-tiling) menggantikan Tiling Assistant"
UUID=tilingshell@ferrarodomenico.com
if [ ! -d ~/.local/share/gnome-shell/extensions/$UUID ]; then
  URL=$(curl -s "https://extensions.gnome.org/extension-info/?uuid=$UUID&shell_version=$(gnome-shell --version | grep -oE '[0-9]+' | head -1)" \
        | python3 -c 'import json,sys; print(json.load(sys.stdin)["download_url"])')
  curl -sL -o /tmp/ts.zip "https://extensions.gnome.org$URL"
  gnome-extensions install --force /tmp/ts.zip; rm -f /tmp/ts.zip
fi
gnome-extensions disable tiling-assistant@ubuntu.com 2>/dev/null || true
EN=$(gsettings get org.gnome.shell enabled-extensions)
echo "$EN" | grep -q $UUID || gsettings set org.gnome.shell enabled-extensions "$(echo "$EN" | sed "s/]$/, '$UUID']/; s/\[, /[/; s/@as \[\]/['$UUID']/")"
TS="gsettings --schemadir $HOME/.local/share/gnome-shell/extensions/$UUID/schemas set org.gnome.shell.extensions.tilingshell"
$TS enable-autotiling true
# layout Kirana: master+stack (ala Hyprland), 50/50, tiga kolom
$TS layouts-json '[{"id":"Kirana Master","tiles":[{"x":0,"y":0,"width":0.6,"height":1,"groups":[1]},{"x":0.6,"y":0,"width":0.4,"height":0.5,"groups":[1,2]},{"x":0.6,"y":0.5,"width":0.4,"height":0.5,"groups":[2,1]}]},{"id":"Kirana Duo","tiles":[{"x":0,"y":0,"width":0.5,"height":1,"groups":[1]},{"x":0.5,"y":0,"width":0.5,"height":1,"groups":[1]}]},{"id":"Kirana Trio","tiles":[{"x":0,"y":0,"width":0.333,"height":1,"groups":[1]},{"x":0.333,"y":0,"width":0.334,"height":1,"groups":[1,2]},{"x":0.667,"y":0,"width":0.333,"height":1,"groups":[2]}]}]'
$TS selected-layouts "[['Kirana Master'], ['Kirana Master'], ['Kirana Master'], ['Kirana Master']]"
$TS inner-gaps 10
$TS outer-gaps 10
$TS enable-window-border true
$TS window-use-custom-border-color true
$TS window-border-width 2
$TS enable-smart-window-border-radius true
$TS show-indicator false
$TS enable-blur-snap-assistant false          # blur = berat di VM tanpa GPU
$TS enable-blur-selected-tilepreview false
$TS window-border-color "$(. /usr/share/kirana/themes/$(cat ~/.config/kirana/current 2>/dev/null || echo senja).theme; echo $ACCENT)"
echo "Selesai. Logout/login sekali agar Tiling Shell aktif."
